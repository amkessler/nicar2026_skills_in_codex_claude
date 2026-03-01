import subprocess
import json
import stat
import glob
import shutil
from pathlib import Path

## When the project was initially created, it wrote out the
## project slug to kernel_config.json
## We use this to target the kernel in the .venv folder later.
with open('kernel_config.json', 'r') as jf:
    config = json.load(jf)
KERNEL_NAME = config['kernel_name']

## Set the project-specific paths for jupyter and ipython
ENV_FILE_PATH = Path('.env')
JUPYTER_ENV_SETTINGS = {
    "JUPYTER_PATH": ".venv/share/jupyter",
    "JUPYTER_CONFIG_DIR": ".venv/etc/jupyter",
    "JUPYTER_RUNTIME_DIR": ".venv/tmp/jupyter",
}

existing_lines = []
if ENV_FILE_PATH.exists():
    existing_lines = ENV_FILE_PATH.read_text().splitlines()

filtered_lines = []
for line in existing_lines:
    stripped = line.strip()
    if any(
        stripped.startswith(f"{key}=") or stripped.startswith(f"export {key}=")
        for key in JUPYTER_ENV_SETTINGS
    ):
        continue
    filtered_lines.append(line)

with ENV_FILE_PATH.open('w') as f:
    if filtered_lines:
        f.write("\n".join(filtered_lines).rstrip() + "\n\n")
    f.write("# Jupyter environment isolation\n")
    for key, value in JUPYTER_ENV_SETTINGS.items():
        f.write(f"{key}={value}\n")

## Install our project kernel. The kernel.json this
## creates gets overwritten later.
subprocess.run([
    'uv', 'run', 'python', '-m', 'ipykernel', 'install',
    f"--name={KERNEL_NAME}",
    '--prefix=.venv'
], check=True)

## Remove the python3 kernel that is added by default
remove_python3 = subprocess.run([
    'uv', 'run', 'jupyter', 'kernelspec', 'remove',
    '--f', 'python3'
], capture_output=True, text=True)
if remove_python3.returncode != 0:
    combined_output = f"{remove_python3.stdout}\n{remove_python3.stderr}"
    if "Couldn't find kernel spec(s): python3" not in combined_output:
        raise subprocess.CalledProcessError(
            remove_python3.returncode,
            remove_python3.args,
            output=remove_python3.stdout,
            stderr=remove_python3.stderr,
        )

## Git hack to make working directory in every notebook at the root of the project.
## Overwrite the kernel json, telling the kernel to use the kernel shell script.
VENV_DIR = Path('.venv')
KERNEL_DIR = Path(f'.venv/share/jupyter/kernels/{KERNEL_NAME}')
kernel_json_data = {
    "argv": [
        str((KERNEL_DIR / "kernel.sh").resolve()),
        "{connection_file}"
    ],
    "name": KERNEL_NAME,
    "display_name": KERNEL_NAME,
    "language": "python",
    "metadata": {
        "debugger": True
    }
}
with open(KERNEL_DIR / 'kernel.json', 'w') as kernel_json_file:
    json.dump(kernel_json_data, kernel_json_file, indent=2)

## Create that shell script
## (uses git to find root then launches kernel from there)
kernel_sh_contents = f'''#!/bin/bash
cd "$(git rev-parse --show-toplevel)"
exec {VENV_DIR.resolve()}/bin/python -m ipykernel_launcher -f "$1"
'''

kernel_sh_path = KERNEL_DIR / 'kernel.sh'
with open(kernel_sh_path, 'w') as kernel_sh_file:
    kernel_sh_file.write(kernel_sh_contents)

## Execution permissions (equivalent to chmod 777)
kernel_sh_path.chmod(kernel_sh_path.stat().st_mode | stat.S_IEXEC | stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)

## Copy templates over to venv jupyter location so
## jupyterlab_templates can find them
TEMPLATE_PATHS = glob.glob('analysis/notebook_templates/*')
template_dest = VENV_DIR.resolve() / "share/jupyter/notebook_templates"
template_dest.mkdir(parents=True, exist_ok=True)
for path in TEMPLATE_PATHS:
    source_path = Path(path)
    destination_path = template_dest / source_path.name
    if destination_path.exists():
        if destination_path.is_dir():
            shutil.rmtree(destination_path)
        else:
            destination_path.unlink()
    if source_path.is_dir():
        shutil.copytree(source_path, destination_path)
    else:
        shutil.copy2(source_path, destination_path)
## Enable the jupyterlab_templates server
subprocess.run([
    'uv', 'run', 'jupyter', 'server', 'extension', 'enable',
    '--py', 'jupyterlab_templates'
], check=True)
