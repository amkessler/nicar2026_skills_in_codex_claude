import subprocess
import json
import stat
import glob
from pathlib import Path

## When the project was initially created, it wrote out the
## project slug to kernel_config.json
## We use this to target the kernel in the .venv folder later.
with open('kernel_config.json', 'r') as jf:
    config = json.load(jf)
KERNEL_NAME = config['kernel_name']

## Set the project-specific paths for jupyter and ipython
ENV_FILE_PATH = Path('.env')
with ENV_FILE_PATH.open('w') as f:
    f.write("\n# Jupyter environment isolation\n")
    f.write("JUPYTER_PATH=.venv/share/jupyter\n")
    f.write("JUPYTER_CONFIG_DIR=.venv/etc/jupyter\n")
    f.write("JUPYTER_RUNTIME_DIR=.venv/tmp/jupyter\n")

## Install our project kernel. The kernel.json this
## creates gets overwritten later.
subprocess.run([
    'uv', 'run', 'python', '-m', 'ipykernel', 'install',
    f"--name={KERNEL_NAME}",
    '--prefix=.venv'
], check=True)

## Remove the python3 kernel that is added by default
subprocess.run([
    'uv', 'run', 'jupyter', 'kernelspec', 'remove',
    '--f', 'python3'
], check=True)

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
        "dubugger": True
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
## make the notebook_templates folder in .venv
subprocess.run([
    'mkdir', f"{VENV_DIR.resolve()}/share/jupyter/notebook_templates"
])
for path in TEMPLATE_PATHS:
    subprocess.run([
        'cp', '-r', path,
        f'{VENV_DIR.resolve()}/share/jupyter/notebook_templates'
    ])
## Enable the jupyterlab_templates server
subprocess.run([
    'uv', 'run', 'jupyter', 'server', 'extension', 'enable',
    '--py', 'jupyterlab_templates'
])
