#!/bin/bash

# ==========================================
# Synth Magic - 终极新建 & 删除工具（每个分类可自定义 archive 标题）
# archive 标题保存在每个 subfolder/list.txt 的第一行
# ==========================================


# ==================== 归档生成函数（按时间倒序排序 + 变量展开修复） ====================
generate_archive() {
    local folder="$1"
    local archive_path="$2"

    local list_file="./${folder}/list.txt"
    local page_title="Archive"

    # 读取归档标题（第一行）
    if [ -f "$list_file" ] && [ -s "$list_file" ]; then
        local first_line=$(head -n 1 "$list_file")
        if [[ "$first_line" == TITLE:* ]]; then
            page_title="${first_line#TITLE:}"
            page_title=$(echo "$page_title" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        fi
    fi

    # 默认标题兜底
    if [ -z "$page_title" ] || [ "$page_title" = "Archive" ]; then
        if [ "$folder" = "yappings" ]; then
            page_title="Archive of my Yappings"
        else
            page_title="Archive of my ${folder^}"
        fi
    fi

    # ==================== 去重 + 按日期倒序排序（已适配 || 分隔符） ====================
    if [ -f "$list_file" ]; then
        {
            # 保留 TITLE: 行
            head -n 1 "$list_file" | grep "^TITLE:"
            
            # 数据行：去重 + 按日期倒序
            tail -n +2 "$list_file" 2>/dev/null | \
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
            awk -F'\\|\\|' '
                {
                    filename = $1
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", filename)
                    date = $2
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", date)
                    if (filename != "") {
                        seen[filename] = date
                    }
                }
                END {
                    for (f in seen) {
                        print f "||" seen[f]
                    }
                }
            ' | \
            sort -t'|' -k3,3r
        } > "${list_file}.tmp"

        mv "${list_file}.tmp" "$list_file"
    fi

    # ==================== 生成 archive.html（关键：使用不带单引号的 EOF，让变量展开） ====================
    cat > "${archive_path}" << EOF
<!DOCTYPE html>
<html lang="en" color-mode="user">
<head>
    <link rel="icon" href="../assets/favicon.png" type="image/png">
    <link rel="stylesheet" href="../style.css">
    <link href="https://fonts.googleapis.com/css2?family=Ysabeau+Office:ital,wght@0,1..1000;1,1..1000&display=swap" rel="stylesheet">
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${page_title}</title>
</head>
<body>
    <header>
        <nav>
            <a href="../index.html"> Home </a>
        </nav>
        <h1>${page_title}</h1>
    </header>

    <main>
    <ul>
EOF

    # 输出已排序的文章列表
    if [ -f "$list_file" ]; then
        tail -n +2 "$list_file" | while IFS= read -r line || [ -n "$line" ]; do
            [ -z "$line" ] && continue

            local filename=$(echo "$line" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            local date=$(echo "$line" | cut -d'|' -f3 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            local display_title=$(echo "$filename" | sed 's/\.html$//; s/_/ /g')

            cat >> "${archive_path}" << EOF
        <li><a href="./${filename}">${display_title}</a> —— ${date}</li>
EOF
        done
    else
        cat >> "${archive_path}" << EOF
        <li>暂无文章</li>
EOF
    fi

    cat >> "${archive_path}" << EOF
    </ul>
    </main>

</body>
<footer>
    <hr>
    <p>© <span id="current_year"></span> Synth Magic</p>
    <script>
        document.getElementById("current_year").innerText = (new Date()).getFullYear().toString();
    </script>
</footer>
</html>
EOF
}
# ==================== 显示帮助 ====================
show_help() {
    echo "Synth Magic 新建 & 删除 & 刷新工具"
    echo ""
    echo "用法："
    echo "  ./new.sh \"文章标题\"                    # 在 yappings 中新建文章"
    echo "  ./new.sh <分类> \"文章标题\"             # 在指定分类中新建文章（如 essays、notes）"
    echo "  ./new.sh page \"页面标题\"               # 在根目录新建独立页面"
    echo "  ./new.sh rm \"标题或文件名\"             # 删除 yappings 中的文章"
    echo "  ./new.sh rm <分类> \"标题或文件名\"      # 删除指定分类中的文章"
    echo "  ./new.sh refresh                        # 刷新 yappings 的 archive.html"
    echo "  ./new.sh refresh <分类>                 # 刷新指定分类的 archive.html"
    echo "  ./new.sh --help                         # 显示此帮助信息"
    echo ""
    echo "示例："
    echo "  ./new.sh \"今天随笔\""
    echo "  ./new.sh essays \"深度学习笔记\""
    echo "  ./new.sh page \"关于我\""
    echo "  ./new.sh rm \"今天随笔\""
    echo "  ./new.sh rm essays \"深度学习笔记\""
    echo "  ./new.sh refresh"
    echo "  ./new.sh refresh essays"
    echo ""
    echo "注意："
    echo "  - 如果要新建的文章已存在，脚本会提示错误"
    echo "  - 每个分类的 archive.html 标题可在首次创建时自定义"
    exit 0
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
fi

if [ -z "$1" ]; then
    show_help
fi

# ====================== 只刷新归档功能 ======================
if [ "$1" = "refresh" ] || [ "$1" = "update" ]; then
    if [ -n "$2" ]; then
        FOLDER="$2"
    else
        FOLDER="yappings"
    fi

    if [ "$FOLDER" = "yappings" ]; then
        ARCHIVE_PATH="./archive.html"
    else
        ARCHIVE_PATH="./${FOLDER}/archive.html"
    fi

    if [ ! -d "./${FOLDER}" ]; then
        echo "错误：文件夹 ./${FOLDER} 不存在！"
        exit 1
    fi

    echo "正在刷新归档：${FOLDER}"
    generate_archive "$FOLDER" "$ARCHIVE_PATH"
    echo "✅ 归档刷新完成：$ARCHIVE_PATH"
    exit 0
fi

# ====================== 删除模式 ======================
if [ "$1" = "rm" ] || [ "$1" = "del" ] || [ "$1" = "remove" ]; then
    if [ -n "$3" ]; then
        FOLDER="$2"
        TITLE="$3"
    else
        FOLDER="yappings"
        TITLE="$2"
    fi

    if [ -z "$TITLE" ]; then
        echo "错误：请提供要删除的标题或文件名！"
        exit 1
    fi

    if [[ "$TITLE" == *.html ]]; then
        filename="$TITLE"
    else
        filename=$(echo "$TITLE" | tr ' ' '_')
        [[ "$filename" != *.html ]] && filename="${filename}.html"
    fi

    FILE_PATH="./${FOLDER}/${filename}"
    LIST_FILE="./${FOLDER}/list.txt"

    if [ ! -f "$FILE_PATH" ]; then
        echo "错误：文件不存在 → $FILE_PATH"
        exit 1
    fi

    echo "⚠️  即将删除：$FILE_PATH"
    read -p "确认删除？(y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "已取消删除。"
        exit 0
    fi

    rm "$FILE_PATH"

    # 从 list.txt 中移除记录（跳过第一行标题行）
    if [ -f "$LIST_FILE" ]; then
        head -n 1 "$LIST_FILE" > "${LIST_FILE}.tmp"
        tail -n +2 "$LIST_FILE" | grep -v "^${filename}||" >> "${LIST_FILE}.tmp"
        mv "${LIST_FILE}.tmp" "$LIST_FILE"
    fi

    # 更新归档
    if [ "$FOLDER" = "yappings" ]; then
        ARCHIVE_PATH="./archive.html"
    else
        ARCHIVE_PATH="./${FOLDER}/archive.html"
    fi

    generate_archive "$FOLDER" "$ARCHIVE_PATH"
    echo "✅ 文件已删除，归档已更新：$ARCHIVE_PATH"
    exit 0
fi

# ====================== 新建模式 ======================
if [ "$1" = "page" ]; then
    MODE="page"
    TITLE="$2"
    FOLDER="."
elif [ -n "$2" ]; then
    FOLDER="$1"
    TITLE="$2"
    MODE="post"
else
    FOLDER="yappings"
    TITLE="$1"
    MODE="post"
fi

if [ -z "$TITLE" ]; then
    echo "错误：请输入标题！"
    show_help
fi

sanitized_name=$(echo "$TITLE" | tr ' ' '_')
[[ "$sanitized_name" != *.html ]] && sanitized_name="${sanitized_name}.html"
# ====================== 新建文章前检查是否存在 ======================
if [ "$MODE" = "post" ]; then
    if [ -f "./${FOLDER}/$sanitized_name" ]; then
        echo "❌ 错误：文件已存在！"
        echo "   文件路径：./${FOLDER}/$sanitized_name"
        echo "   请使用其他标题，或先使用 rm 命令删除后再创建。"
        exit 1
    fi
fi
# ====================== 处理分类归档标题 ======================
LIST_FILE="./${FOLDER}/list.txt"
ARCHIVE_PATH="./archive.html"

if [ "$FOLDER" = "yappings" ]; then
    ARCHIVE_PATH="./archive.html"
    DEFAULT_TITLE="Archive of my Yappings"
else
    ARCHIVE_PATH="./${FOLDER}/archive.html"
    DEFAULT_TITLE="Archive of my ${FOLDER^}"
fi

# 如果是新分类（list.txt 不存在或没有 TITLE: 开头），询问自定义标题
if [ ! -f "$LIST_FILE" ] || ! grep -q "^TITLE:" "$LIST_FILE"; then
    echo "首次为分类 [${FOLDER}] 创建归档"
    read -p "请输入该分类的归档页面标题（直接回车使用默认: ${DEFAULT_TITLE}）: " custom_title
    if [ -n "$custom_title" ]; then
        PAGE_TITLE="$custom_title"
    else
        PAGE_TITLE="$DEFAULT_TITLE"
    fi
    echo "TITLE: ${PAGE_TITLE}" > "$LIST_FILE"
    echo "✅ 已为 [${FOLDER}] 设置归档标题：${PAGE_TITLE}"
else
    # 已存在标题，从第一行读取
    PAGE_TITLE=$(head -n 1 "$LIST_FILE" | sed 's/^TITLE: *//')
fi

if [ "$MODE" = "page" ]; then
    # 页面模板（省略，保持不变）
    cat <<EOF > "./$sanitized_name"
<!DOCTYPE html>
<html lang="en" color-mode="user">
<head>
    <script>window.MathJax={tex:{inlineMath:[['\$','\$']],displayMath:[['\$\$','\$\$']]}};</script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@4/tex-mml-chtml.js"></script>
    <link rel="icon" href="./assets/favicon.png" type="image/png">
    <link href="./prism.css" rel="stylesheet" />
    <link href="https://fonts.googleapis.com/css2?family=Ysabeau+Office:ital,wght@0,1..1000;1,1..1000&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="./style.css">
    <meta charset="utf-8">
    <meta name="description" content="${TITLE}">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${TITLE} - Synth Magic</title>
</head>
<body class="line-numbers">
    <script src="./prism.js"></script>
    <script>Prism.plugins.NormalizeWhitespace.setDefaults({"remove-trailing":true,"remove-indent":true,"left-trim":true,"right-trim":true});</script>

    <header>
        <nav>
            <ul><a href="./index.html">Home</a></ul>
        </nav>
        <h1>${TITLE}</h1>
    </header>

    <main>
        <article>
            <p>在这里开始写你的页面内容...</p>
        </article>
    </main>

</body>
<footer>
    <hr>
    <p>© <span id="current_year"></span> Synth Magic</p>
    <script>document.getElementById("current_year").innerText = (new Date()).getFullYear().toString();</script>
</footer>
</html>
EOF
    echo "✅ 独立页面创建成功：./${sanitized_name}"

else
    # 创建文章
    mkdir -p "./${FOLDER}"

    cat <<EOF > "./${FOLDER}/$sanitized_name"
<!DOCTYPE html>
<html lang="en" color-mode="user">
<head>
    <script>window.MathJax={tex:{inlineMath:[['\$','\$']],displayMath:[['\$\$','\$\$']]}};</script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@4/tex-mml-chtml.js"></script>
    <link rel="icon" href="../assets/favicon.png" type="image/png">
    <link href="../prism.css" rel="stylesheet" />
    <link href="https://fonts.googleapis.com/css2?family=Ysabeau+Office:ital,wght@0,1..1000;1,1..1000&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../style.css">
    <meta charset="utf-8">
    <meta name="description" content="My description">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${TITLE}</title>
</head>
<body class="line-numbers">
    <script src="../prism.js"></script>
    <script>Prism.plugins.NormalizeWhitespace.setDefaults({"remove-trailing":true,"remove-indent":true,"left-trim":true,"right-trim":true});</script>

    <header>
        <nav>
            <ul><a href="../index.html">Home</a></ul>
        </nav>
        <h2>${TITLE}</h2>
    </header>

    <main>
        <p>Date: $(date +%F)</p>
        <hr>
        <article>
            <p>在这里开始写你的内容...</p>
        </article>
    </main>

</body>
<footer>
    <hr>
    <p>© <span id="current_year"></span> Synth Magic</p>
    <script>document.getElementById("current_year").innerText = (new Date()).getFullYear().toString();</script>
</footer>
</html>
EOF

    # 添加文章记录（从第二行开始）
    NEW_ENTRY="${sanitized_name}||$(date +%F)"
    echo "$NEW_ENTRY" >> "$LIST_FILE"

    echo "✅ 文章创建成功：./${FOLDER}/$sanitized_name"

    # 更新归档
    generate_archive "$FOLDER" "$ARCHIVE_PATH"
    echo "✅ 归档已更新：$ARCHIVE_PATH （标题：${PAGE_TITLE}）"
fi

echo "🎉 操作全部完成！"