import asyncio
import difflib
import shlex
from typing import Tuple
import sys
import os

# دالة للتحقق من وجود الملفات بشكل مرن متوافق مع الاستضافات السحابية
def get_absolute_path(filename: str) -> str:
    if os.path.exists(filename):
        return filename
    # إذا لم يجد الملف، يبحث عنه في مجلد العمل الحالي (مثال: /app على رايلوي)
    current_dir_file = os.path.join(os.getcwd(), os.path.basename(filename))
    if os.path.exists(current_dir_file):
        return current_dir_file
    return filename

async def lines_difference(file1, file2):
    file1 = get_absolute_path(file1)
    file2 = get_absolute_path(file2)
    
    try:
        with open(file1, "r", encoding="utf-8") as f1:
            lines1 = [line.rstrip("\n") for line in f1.readlines()]
        with open(file2, "r", encoding="utf-8") as f2:
            lines2 = [line.rstrip("\n") for line in f2.readlines()]
    except FileNotFoundError as e:
        print(f"⚠️ [Updater] تخطي تحديث المكتبات: لم يتم العثور على الملف -> {e.filename}")
        return [], []

    diff = difflib.unified_diff(
        lines1, lines2, fromfile=file1, tofile=file2, lineterm="", n=0
    )
    lines = list(diff)[2:]
    added = [line[1:] for line in lines if line[0] == "+"]
    removed = [line[1:] for line in lines if line[0] == "-"]
    additions = [i for i in added if i not in removed]
    removedt = [i for i in removed if i not in added]
    return additions, removedt


async def runcmd(cmd: str) -> Tuple[str, str, int, int]:
    args = shlex.split(cmd)
    process = await asyncio.create_subprocess_exec(
        *args, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await process.communicate()
    return (
        stdout.decode("utf-8", "replace").strip(),
        stderr.decode("utf-8", "replace").strip(),
        process.returncode,
        process.pid,
    )


async def update_requirements(main, test):
    a, r = await lines_difference(main, test)
    if not a:
        print("✅ [Updater] جميع المكتبات محدثة بالفعل.")
        return
        
    try:
        for i in a:
            # تنظيف النص لتجنب الأسطر الفارغة أو التعليقات في ملف requirements
            package = i.strip()
            if package and not package.startswith("#"):
                print(f"⏳ جاري تثبيت المكتبة الجديدة: {package} ...")
                stdout, stderr, code, pid = await runcmd(f"pip install {package}")
                if code == 0:
                    print(f"✅ تم تثبيت {package} بنجاح.")
                else:
                    print(f"❌ فشل تثبيت {package}: {stderr}")
    except Exception as e:
        print(f"⚠️ خطأ أثناء تحديث المكتبات: {str(e)}")


if __name__ == "__main__":
    # التحقق من أن الوسائط تم تمريرها بشكل صحيح، وإلا نضع قيم افتراضية منعاً للـ Crash
    main_file = sys.argv[1] if len(sys.argv) > 1 else "requirements.txt"
    test_file = sys.argv[2] if len(sys.argv) > 2 else "requirements.txt"

    loop = asyncio.get_event_loop()
    loop.run_until_complete(update_requirements(main_file, test_file))
    loop.close()    )


async def update_requirements(main , test):
    a, r = await lines_differnce(main, test)
    try:
        for i in a:
            await runcmd(f"pip install {i}")
            print(f"Succesfully installed {i}")
    except Exception as e:
        print(f"Error while installing requirments {str(e)}")


loop = asyncio.get_event_loop()
loop.run_until_complete(update_requirements(sys.argv[1] , sys.argv[2]))
loop.close()
