#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import subprocess
import math
import sys
import shutil
import argparse # <--- 导入 argparse

def run_cmd(command, check=True, capture_output=False, text=True, shell=False):
    """
    辅助函数，用于运行外部命令并进行基本的错误处理。
    (代码同上一个版本，保持不变)
    """
    cmd_str = ' '.join(command) if isinstance(command, list) else command
    print(f"--- Running Command: {cmd_str}")
    try:
        result = subprocess.run(command, check=check, capture_output=capture_output, text=text, shell=shell)
        # 仅在成功时打印输出，减少冗余信息
        if check and result.returncode == 0:
             if capture_output and result.stdout.strip():
                 print(f"    stdout: {result.stdout.strip()}")
             if capture_output and result.stderr.strip():
                 # 将stderr也打印到stdout，方便查看
                 print(f"    stderr: {result.stderr.strip()}")
        return result
    except subprocess.CalledProcessError as e:
        print(f"!!! Command Failed: {' '.join(e.cmd) if isinstance(e.cmd, list) else e.cmd}", file=sys.stderr)
        print(f"    Return code: {e.returncode}", file=sys.stderr)
        if e.stdout:
            print(f"    stdout:\n{e.stdout}", file=sys.stderr)
        if e.stderr:
            print(f"    stderr:\n{e.stderr}", file=sys.stderr)
        sys.exit(1) # 发生错误时退出脚本
    except FileNotFoundError:
        print(f"!!! Error: Command not found: {command[0]}", file=sys.stderr)
        print("    Please ensure the necessary command-line tools (du, truncate, mkfs.ext4, mount, umount, cp) are installed and in the PATH.", file=sys.stderr)
        sys.exit(1)

def main():
    """主执行函数"""

    # --- 使用 argparse 解析命令行参数 ---
    parser = argparse.ArgumentParser(
        description="从已挂载文件系统的子目录创建独立的 ext4 文件系统镜像。"
    )
    parser.add_argument(
        "subdir_name", # 定义为一个必需的位置参数
        help="源挂载点 (./mnt) 下要制作为镜像的子目录名称 (例如 'glibc', 'musl')"
    )
    # 可以选择性地添加更多参数，例如指定源挂载点、输出文件名模式等
    # parser.add_argument("--mount-point", default="./mnt", help="源文件系统挂载点")
    args = parser.parse_args()
    # --- 参数解析完毕 ---


    # --- 配置参数 (部分来自命令行) ---
    source_base_mount = "./mnt"       # 原始文件系统的挂载点 (可以考虑也做成参数)
    source_subdir = args.subdir_name  # <--- 从命令行参数获取子目录名
    output_image_file = f"./img/{source_subdir}.img" # <--- 输出文件名基于子目录名
    temp_mount_point = f"./tmp_{source_subdir}_mnt" # <--- 临时挂载点名基于子目录名
    # ----------------

    source_full_path = os.path.join(source_base_mount, source_subdir)

    print(f"*** Starting process to create '{output_image_file}' from '{source_full_path}' ***")

    # --- 检查执行权限 ---
    if os.geteuid() != 0:
       print("\n!!! Warning: This script performs operations (mount, mkfs, preserving file ownership)", file=sys.stderr)
       print("!!! that usually require root privileges. You might need to run it using 'sudo'.", file=sys.stderr)

    # --- 步骤 1: 检查源目录是否存在 ---
    print(f"\n[Step 1/9] Checking if source directory exists: '{source_full_path}'")
    if not os.path.isdir(source_full_path):
        print(f"!!! Error: Source directory '{source_full_path}' not found.", file=sys.stderr)
        print(f"    Please ensure the original filesystem is mounted at '{source_base_mount}'", file=sys.stderr)
        print(f"    and contains the subdirectory '{source_subdir}'.", file=sys.stderr)
        sys.exit(1)
    print(" -> Source directory found.")

    # --- 步骤 2: 计算所需镜像大小 ---
    print(f"\n[Step 2/9] Calculating required size for contents of '{source_full_path}'...")
    du_result = run_cmd(["du", "-sb", source_full_path], capture_output=True)
    try:
        size_bytes = int(du_result.stdout.split()[0])
    except (ValueError, IndexError) as e:
        print(f"!!! Error: Could not parse size from du output: '{du_result.stdout.strip()}' ({e})", file=sys.stderr)
        sys.exit(1)

    buffer_factor = 1.30
    min_extra_mib = 150
    required_size_bytes = max(int(size_bytes * buffer_factor), size_bytes + min_extra_mib * 1024 * 1024)
    required_size_mib = math.ceil(required_size_bytes / (1024 * 1024))
    print(f" -> Source content size: {size_bytes / (1024*1024):.2f} MiB")
    print(f" -> Calculated image size (with buffer): {required_size_mib} MiB")

    # --- 步骤 3: 创建新的空镜像文件 ---
    print(f"\n[Step 3/9] Creating empty image file: '{output_image_file}' ({required_size_mib} MiB)")
    run_cmd(["truncate", "-s", f"{required_size_mib}M", output_image_file])
    print(f" -> Empty image file '{output_image_file}' created.")

    # --- 步骤 4: 格式化新镜像文件为 ext4 ---
    print(f"\n[Step 4/9] Formatting '{output_image_file}' as ext4...")
    run_cmd(["sudo", "mkfs.ext4", "-F", output_image_file])
    print(f" -> Image file '{output_image_file}' formatted successfully.")

    # --- 步骤 5-9: 挂载、复制、卸载（包含清理） ---
    mounted = False
    try:
        # --- 步骤 5: 创建临时挂载点 ---
        print(f"\n[Step 5/9] Creating temporary mount point: '{temp_mount_point}'")
        os.makedirs(temp_mount_point, exist_ok=True)
        print(f" -> Temporary mount point '{temp_mount_point}' ensured.")

        # --- 步骤 6: 挂载新镜像文件 ---
        print(f"\n[Step 6/9] Mounting new image '{output_image_file}' to '{temp_mount_point}'...")
        run_cmd(["sudo", "mount", "-o", "loop", output_image_file, temp_mount_point])
        mounted = True
        print(f" -> Image mounted successfully.")

        # --- 步骤 7: 复制内容 ---
        print(f"\n[Step 7/9] Copying contents from '{source_full_path}' to the new image root...")
        source_contents_path = os.path.join(source_full_path, ".")
        dest_path = temp_mount_point + os.sep
        run_cmd(["sudo", "cp", "-a", source_contents_path, dest_path])
        print(" -> Contents copied successfully.")

    except Exception as e:
        print(f"\n!!! An error occurred during mount/copy operations: {e}", file=sys.stderr)
        raise # 重新抛出异常

    finally:
        # --- 步骤 8: 卸载新镜像 (如果已挂载) ---
        if mounted:
            print(f"\n[Step 8/9] Unmounting '{temp_mount_point}'...")
            try:
                 # 使用 subprocess.run 而不是 run_cmd，避免在 finally 中因 sys.exit 中断
                 umount_result = subprocess.run(["sudo", "umount", temp_mount_point], check=False, capture_output=True, text=True)
                 if umount_result.returncode == 0:
                     print(" -> Unmounted successfully.")
                 else:
                     print(f"!!! Warning: Failed to unmount '{temp_mount_point}'. RC={umount_result.returncode}", file=sys.stderr)
                     if umount_result.stderr: print(f"    stderr: {umount_result.stderr.strip()}", file=sys.stderr)
            except Exception as umount_e:
                 print(f"!!! Exception during unmount: {umount_e}", file=sys.stderr)

        # --- 步骤 9: 删除临时挂载点 (如果存在) ---
        if os.path.exists(temp_mount_point):
            print(f"\n[Step 9/9] Removing temporary mount point: '{temp_mount_point}'")
            try:
                os.rmdir(temp_mount_point)
                print(" -> Temporary mount point removed.")
            except OSError as e:
                print(f"!!! Warning: Could not remove directory '{temp_mount_point}': {e}", file=sys.stderr)
                print("    This might happen if unmounting failed. Manual cleanup may be needed.", file=sys.stderr)

    print("\n" + "="*40)
    print(f"*** Success! New ext4 image created: '{output_image_file}' ***")
    print("="*40 + "\n")


if __name__ == "__main__":
    main()