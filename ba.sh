#!/bin/bash

# ====================================================
# يدعم الريبو الخاص عن طريق GITHUB_TOKEN
# UPSTREAM_REPO   = رابط ريبوك الخاص
# UPSTREAM_REPO_BRANCH = الفرع (الافتراضي: master)
# GITHUB_TOKEN    = توكن GitHub للريبو الخاص
# BOT_MODULE      = اسم المودول لتشغيله (الافتراضي: Tython)
# ====================================================

_get_ziplink () {
    local regex
    regex='(https?)://github.com/.+/.+'
    local branch="${UPSTREAM_REPO_BRANCH:-master}"

    if [[ $UPSTREAM_REPO =~ $regex ]]
    then
        if [[ $GITHUB_TOKEN ]]
        then
            # إدراج التوكن في الرابط للوصول للريبو الخاص
            local url_with_token
            url_with_token=$(echo "$UPSTREAM_REPO" | sed "s|https://github.com|https://${GITHUB_TOKEN}@github.com|")
            echo "${url_with_token}/archive/${branch}.zip"
        else
            echo "${UPSTREAM_REPO}/archive/${branch}.zip"
        fi
    else
        echo "لم يتم تحديد UPSTREAM_REPO بشكل صحيح" >&2
        exit 1
    fi
}

_get_repolink () {
    local regex
    local rlink
    regex='(https?)://github.com/.+/.+'
    if [[ $UPSTREAM_REPO =~ $regex ]]
    then
        if [[ $GITHUB_TOKEN ]]
        then
            rlink=$(echo "$UPSTREAM_REPO" | sed "s|https://github.com|https://${GITHUB_TOKEN}@github.com|")
        else
            rlink="$UPSTREAM_REPO"
        fi
    else
        echo "يجب تحديد UPSTREAM_REPO" >&2
        exit 1
    fi
    echo "$rlink"
}

_run_python_code() {
    python3 -c "$1"
}

_run_cat_git() {
    local repolink
    repolink=$(_get_repolink)
    local branch="${UPSTREAM_REPO_BRANCH:-master}"
    _run_python_code "
from git import Repo
import sys
OFFICIAL_UPSTREAM_REPO = '${repolink}.git'
ACTIVE_BRANCH_NAME = '${branch}'
try:
    repo = Repo.init()
    origin = repo.create_remote('temponame', OFFICIAL_UPSTREAM_REPO)
    origin.fetch()
    repo.create_head(ACTIVE_BRANCH_NAME, origin.refs[ACTIVE_BRANCH_NAME])
    repo.heads[ACTIVE_BRANCH_NAME].checkout(True)
except Exception as e:
    print(f'git setup skipped: {e}')
"
}

_set_bot () {
    local zippath
    zippath="master.zip"
    local module="${BOT_MODULE:-Tython}"

    echo "⌭ جاري تنزيل اكواد السورس ⌭"
    local ziplink
    ziplink=$(_get_ziplink)

    # تحميل بدون طباعة الرابط (لإخفاء التوكن من اللوقات)
    wget -q "$ziplink" -O "$zippath"

    if [[ ! -f "$zippath" ]]; then
        echo "❌ فشل تحميل السورس - تحقق من UPSTREAM_REPO و GITHUB_TOKEN"
        exit 1
    fi

    echo "⌭ تفريغ البيانات ⌭"
    CATPATH=$(zipinfo -1 "$zippath" | head -1 | cut -d/ -f1)
    unzip -qq "$zippath"
    echo "⌭ تـم التفريـغ ⌭"

    echo "⌭ يتم التنظيف ⌭"
    rm -rf "$zippath"
    sleep 2

    cd "$CATPATH" || exit 1

    # تحديث المتطلبات إذا تغيرت
    if [[ -f requirements.txt ]]; then
        python3 ../setup/updater.py ../requirements.txt requirements.txt
    fi

    # إعداد git للتحديثات (اختياري)
    _run_cat_git

    chmod -R 755 bin 2>/dev/null || true

    echo "⌭ جاري بدء تشغيل $module ⌭"
    echo ""
    python3 -m "$module"
}

_set_bot
