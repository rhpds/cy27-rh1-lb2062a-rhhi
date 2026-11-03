"""Exercise the legacy Ansible wrapper and QA failure reporting locally.

These tests use an isolated temporary playbook tree and a local Ansible host;
they never invoke Podman or change a provisioned lab.
"""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ANSIBLE = shutil.which("ansible-playbook")



def run_playbook(playbook, *, env=None, extra_vars=None, cwd=None):
    command = [ANSIBLE, "-i", "rhel,", "-c", "local", str(playbook)]
    if extra_vars:
        for key, value in extra_vars.items():
            command.extend(["-e", f"{key}={value}"])
    return subprocess.run(
        command,
        cwd=cwd,
        env={**os.environ, "ANSIBLE_NOCOLOR": "1", "ANSIBLE_LOCAL_TEMP": "/tmp/ansible-rhhi-test", **(env or {})},
        capture_output=True,
        text=True,
        timeout=90,
        check=False,
    )


def runtime_tree(tmp_path):
    runtime = tmp_path / "runtime"
    runtime.mkdir()
    wrapper = (ROOT / "runtime-automation/main.yml").read_text()
    # No privilege escalation is needed when the temporary target is localhost.
    wrapper = wrapper.replace("          become: true\n", "          become: false\n")
    (runtime / "main.yml").write_text(wrapper)
    module = runtime / "example"
    module.mkdir()
    output = tmp_path / "job"
    output.mkdir()
    return runtime, module, output



@unittest.skipUnless(ANSIBLE, "ansible-playbook is not installed")
class ValidationOutputTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="rhhi-validation-")
        self.addCleanup(self.temp.cleanup)
        self.tmp_path = Path(self.temp.name)

    def test_runtime_failure_produces_only_guidance(self):
        runtime, module, output = runtime_tree(self.tmp_path)
        (module / "validation-rhel.sh").write_text(
            "#!/bin/sh\nset -e\necho 'before'\n"
            "fail_validation - <<'EOF'\nMissing image\nBuild it first.\nEOF\n"
        )
        result = run_playbook(
            runtime / "main.yml",
            cwd=runtime,
            env={"BASTION_HOST": "rhel", "BASTION_PORT": "22"},
            extra_vars={"module_dir": "example", "module_stage": "validation", "job_info_dir": output},
        )
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(output.joinpath("validation_failure.out").read_text(), "Missing image\nBuild it first.")
        self.assertIn("= FAIL VALIDATION BEGIN", output.joinpath("script.out").read_text())

    def test_runtime_success_does_not_produce_failure(self):
        runtime, module, output = runtime_tree(self.tmp_path)
        (module / "validation-rhel.sh").write_text("#!/bin/sh\necho 'validated'\n")
        result = run_playbook(
            runtime / "main.yml",
            cwd=runtime,
            env={"BASTION_HOST": "rhel", "BASTION_PORT": "22"},
            extra_vars={"module_dir": "example", "module_stage": "validation", "job_info_dir": output},
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("validated", output.joinpath("script.out").read_text())
        self.assertFalse(output.joinpath("validation_failure.out").exists())

    def test_runtime_nonzero_without_marker_does_not_create_validation_message(self):
        runtime, module, output = runtime_tree(self.tmp_path)
        (module / "validation-rhel.sh").write_text("#!/bin/sh\necho 'unexpected error' >&2\nexit 2\n")
        result = run_playbook(
            runtime / "main.yml",
            cwd=runtime,
            env={"BASTION_HOST": "rhel", "BASTION_PORT": "22"},
            extra_vars={"module_dir": "example", "module_stage": "validation", "job_info_dir": output},
        )
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(output.joinpath("validation_failure.out").exists())

    def test_runtime_marker_fails_even_without_nonzero_exit(self):
        runtime, module, output = runtime_tree(self.tmp_path)
        (module / "validation-rhel.sh").write_text(
            "#!/bin/sh\nfail_validation 'Missing image' || true\n"
        )
        result = run_playbook(
            runtime / "main.yml",
            cwd=runtime,
            env={"BASTION_HOST": "rhel", "BASTION_PORT": "22"},
            extra_vars={"module_dir": "example", "module_stage": "validation", "job_info_dir": output},
        )
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(output.joinpath("validation_failure.out").read_text(), "Missing image")

    def test_qa_failure_and_next_stage_do_not_share_message(self):
        qa = self.tmp_path / "qa"
        tasks = qa / "tasks"
        tasks.mkdir(parents=True)
        shutil.copy(ROOT / "qa-automation/tasks/run_script.yml", tasks / "run_script.yml")
        module = self.tmp_path / "example"
        module.mkdir()
        (module / "validation-rhel.sh").write_text(
            "#!/bin/sh\nset -e\nfail_validation 'Missing image'\n"
        )
        # Ansible rescue allows a second include to test stale set_fact state.
        playbook = qa / "test.yml"
        playbook.write_text(
            "---\n- hosts: rhel\n  gather_facts: false\n  vars:\n"
            f"    runtime_path: {self.tmp_path}\n"
            "    module_name: example\n  tasks:\n"
            "    - block:\n"
            "        - ansible.builtin.include_tasks: tasks/run_script.yml\n"
            "          vars:\n            stage_name: validation\n"
            "      rescue:\n"
            "        - ansible.builtin.include_tasks: tasks/run_script.yml\n"
            "          vars:\n            stage_name: setup\n"
            "        - ansible.builtin.assert:\n"
            "            that: _validation_failure == ''\n"
        )
        result = run_playbook(playbook)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Missing image", result.stdout)

    def test_validation_scripts_are_posix_syntax(self):
        for script in (ROOT / "runtime-automation").glob("module-*/validation-rhel.sh"):
            result = subprocess.run(["sh", "-n", str(script)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, f"{script}: {result.stderr}")


if __name__ == "__main__":
    unittest.main()
