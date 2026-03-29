#!/bin/sh

# Define input and output files
INPUT_FILE="./yappings/list.txt"
OUTPUT_FILE="archive.html"

# Remove output file if it exists
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

# Write HTML header
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
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines
    [ -z "$line" ] && continue
    # Remove leading/trailing whitespace from both variables
    # Split the line by || separator
    filename=$(echo "$line" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    createdate=$(echo "$line" | cut -d'|' -f3 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Remove any leading | from creation date if present
    createdate=$(echo "$createdate" | sed 's/^|//')
    
    # Create display name by replacing underscores with spaces
    display_name=$(echo "$filename" | sed 's/_/ /g')
    # Write table row to HTML
    cat >> "$OUTPUT_FILE" << EOF
        <li><a href="./yappings/$filename">$display_name</a> —— $createdate </li>
EOF
done < "$INPUT_FILE"

# Write HTML footer
cat >> "$OUTPUT_FILE" << EOF
    </main>
    <footer>
        <hr>
        <p>© 2025 Synth Magic</p>
    </footer>
</body>

</html>
EOF

echo "HTML file generated: $OUTPUT_FILE"