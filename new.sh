#!/bin/bash

# ==========================================
# PART 1: Create the new Blog Post
# ==========================================

# Check if a filename argument was provided
if [ -z "$1" ]; then
  echo "Usage: $0 \"filename or title\""
  exit 1
fi

# Get the input filename/title
input_name="$1"

# Replace all spaces with underscores
sanitized_name=$(echo "$input_name" | tr ' ' '_')

# Ensure the file ends with .html
case "$sanitized_name" in
    *.html)
        # Filename already ends with .html
        ;;
    *)
        sanitized_name="${sanitized_name}.html"
        ;;
esac

# Ensure directory exists
mkdir -p ./yappings

# Create the file with the basic HTML template
cat <<EOF > "./yappings/$sanitized_name"
<!DOCTYPE html>
<html lang="en" color-mode="user">
<head>
    <script>
        window.MathJax = {
            tex: {
                inlineMath: [['$', '$']],
                displayMath: [['\$\$', '\$\$']]
            }
        };
    </script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@4/tex-mml-chtml.js"></script>
    <link rel="icon" href="../assets/favicon.png" type="image/png">
    <link href="../prism.css" rel="stylesheet" />
    <link rel="stylesheet" href="../style.css">
    <meta charset="utf-8">
    <meta name="description" content="My description">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Synth Magic</title>
</head>
<body class="line-numbers">
    <script src="../prism.js"></script>
    <script>
        Prism.plugins.NormalizeWhitespace.setDefaults({
            "remove-trailing": true,
            "remove-indent": true,
            "left-trim": true,
            "right-trim": true,
        });
    </script>
    <header>
        <nav>
            <ul><a href="../index.html">Home</a></ul>
            <ul><a href="../archive.html">Archive</a></ul>
        </nav>
        <h2>${input_name}</h2>
    </header>
    <main>
        <p>Date: $(date +%F)</p>
        <hr>
        <article>
        <p></p>
        </article>
    </main>
    <footer>
        <br>
        <br>
        <p>© 2025 Synth Magic</p>
    </footer>
</body>
</html>
EOF

# Append to list.txt (using || as separator)
# Note: This creates "filename||date"
# --- PREPEND TO LIST.TXT LOGIC ---
LIST_FILE="./yappings/list.txt"
NEW_ENTRY="${sanitized_name}||$(date +%F)"

if [ -f "$LIST_FILE" ]; then
    # Create a temp file with the new entry first
    echo "$NEW_ENTRY" > "${LIST_FILE}.tmp"
    # Append the old content below it
    cat "$LIST_FILE" >> "${LIST_FILE}.tmp"
    # Move the temp file over the original
    mv "${LIST_FILE}.tmp" "$LIST_FILE"
else
    # If list doesn't exist, just create it
    echo "$NEW_ENTRY" > "$LIST_FILE"
fi
echo "Successfully created blog post: ./yappings/$sanitized_name"

# ==========================================
# PART 2: Re-generate the Archive List
# ==========================================

echo "Updating archive.html..."

# Define input and output files
INPUT_FILE="./yappings/list.txt"
OUTPUT_FILE="archive.html"

# Write HTML header to archive.html (overwriting previous version)
cat > "$OUTPUT_FILE" << EOF
<!DOCTYPE html>
<html lang="en" color-mode="user">

<head>
    <link rel="icon" href="./assets/favicon.png" type="image/png">
    <link rel="stylesheet" href="./style.css">

    <meta charset="utf-8">
    <meta name="description" content="My description">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Synth Magic</title>
</head>

<body>
    <header>
        <nav>
            <a href="index.html"> Home </a>
        </nav>
        <h1>Archive of my Yappings</h1>
    </header>

    <main>
    <ul>
EOF

# Process each line of the input file
if [ -f "$INPUT_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines
        [ -z "$line" ] && continue
        
        # Parse fields based on || separator
        # Field 1: filename
        # Field 3: date (because || creates an empty Field 2)
        filename=$(echo "$line" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        createdate=$(echo "$line" | cut -d'|' -f3 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Remove any leading | from creation date if present (failsafe)
        createdate=$(echo "$createdate" | sed 's/^|//')
        
        # Create display name by replacing underscores with spaces
        display_name=$(echo "$filename" | sed 's/_/ /g')
        
        # Write table row to HTML
        cat >> "$OUTPUT_FILE" << EOF
        <li><a href="./yappings/$filename">$display_name</a> —— $createdate </li>
EOF
    done < "$INPUT_FILE"
else
    echo "Warning: $INPUT_FILE not found."
fi

# Write HTML footer
cat >> "$OUTPUT_FILE" << EOF
    </ul>
    </main>
    <footer>
        <hr>
        <p>© 2025 Synth Magic</p>
    </footer>
</body>

</html>
EOF

echo "Archive updated: $OUTPUT_FILE"