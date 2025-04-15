#!/bin/bash

# Script to convert Markdown blog posts to HTML files
# Usage: ./md_to_html.sh input.md

if [ $# -eq 0 ]; then
  echo "Usage: $0 input.md"
  exit 1
fi

input_file=$1

# Check if file exists
if [ ! -f "$input_file" ]; then
  echo "Error: File '$input_file' not found."
  exit 1
fi

# Extract filename without extension (for title)
filename=$(basename -- "$input_file")
title="${filename%.md}"

# Extract date from the first line if it exists
# Expected format: # YYYYMMDD - Post Title
first_line=$(head -n 1 "$input_file")
date_pattern="([0-9]{8})"

if [[ $first_line =~ $date_pattern ]]; then
  date_str=${BASH_REMATCH[1]}
else
  # If no date in first line, try to extract from filename
  if [[ $filename =~ $date_pattern ]]; then
    date_str=${BASH_REMATCH[1]}
  else
    # Default to current date
    date_str=$(date +"%Y%m%d")
  fi
fi

# Create output filename
output_file="${title}.html"

# Convert markdown to HTML
cat > "$output_file" << EOF
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;600&display=swap');
    
    /* Use Envy Code R for UI elements and headings */
    @font-face {
      font-family: 'Envy Code R';
      src: url('https://cdnjs.cloudflare.com/ajax/libs/webfont/1.6.28/webfontloader.js');
      /* Note: This is a placeholder. Envy Code R should be properly loaded in production */
    }
    
    body {
      background-color: #000;
      color: #ccc;
      font-family: 'Open Sans', sans-serif;
      margin: 0;
      padding: 20px;
      line-height: 1.6;
      max-width: 900px;
      margin: 0 auto;
    }
    
    header {
      margin-bottom: 40px;
    }
    
    h1, h2, h3, nav, .date {
      font-family: 'Envy Code R', monospace;
      font-weight: normal;
    }
    
    h1 {
      font-size: 24px;
      color: #fff;
      margin-bottom: 15px;
    }
    
    h2 {
      font-size: 20px;
      color: #8888ff;
      margin-top: 30px;
      margin-bottom: 15px;
      display: flex;
      align-items: center;
    }
    
    h2::before {
      content: "##";
      color: #8888ff;
      margin-right: 8px;
    }
    
    h3 {
      font-size: 18px;
      color: #aaa;
      margin-top: 25px;
      margin-bottom: 10px;
      display: flex;
      align-items: center;
    }
    
    h3::before {
      content: "###";
      color: #aaa;
      margin-right: 8px;
    }
    
    nav {
      display: flex;
      gap: 20px;
      margin-bottom: 30px;
    }
    
    nav a {
      color: #8888ff;
      text-decoration: none;
      padding: 5px 0;
    }
    
    nav a:hover {
      border-bottom: 1px solid #8888ff;
    }
    
    a {
      color: #ccc;
      text-decoration: underline;
    }
    
    pre, code {
      font-family: 'Envy Code R', monospace;
      background-color: #111;
      padding: 10px;
      overflow-x: auto;
      border-radius: 3px;
    }
    
    code {
      padding: 2px 5px;
    }
    
    blockquote {
      border-left: 3px solid #444;
      padding-left: 15px;
      margin-left: 0;
      color: #888;
    }
    
    .site-title {
      font-size: 24px;
      color: #fff;
    }
    
    .date {
      color: #999;
      margin-bottom: 20px;
    }
    
    hr {
      border: none;
      border-top: 1px solid #333;
      margin: 30px 0;
    }
  </style>
</head>
<body>
  <header>
    <div class="site-title">yourname</div>
    <nav>
      <a href="index.html">about</a>
      <a href="blog.html">blog</a>
      <a href="projects.html">projects</a>
    </nav>
    <h1>${title}</h1>
    <div class="date">${date_str}</div>
  </header>
  
  <main>
EOF

# Process the markdown content
# Since we don't have access to a full markdown converter in bash,
# we'll implement basic MD to HTML conversion for common elements

# Skip the first line if it contains the date/title already processed
tail -n +1 "$input_file" | while IFS= read -r line; do
  # Handle headings
  if [[ $line =~ ^#\ (.*)$ ]]; then
    echo "<h1>${BASH_REMATCH[1]}</h1>" >> "$output_file"
  elif [[ $line =~ ^##\ (.*)$ ]]; then
    echo "<h2>${BASH_REMATCH[1]}</h2>" >> "$output_file"
  elif [[ $line =~ ^###\ (.*)$ ]]; then
    echo "<h3>${BASH_REMATCH[1]}</h3>" >> "$output_file"
  # Handle code blocks (simple version)
  elif [[ $line == "```"* ]]; then
    if [[ $in_code_block == true ]]; then
      echo "</pre>" >> "$output_file"
      in_code_block=false
    else
      echo "<pre><code>" >> "$output_file"
      in_code_block=true
    fi
  # Handle lists (basic)
  elif [[ $line =~ ^-\ (.*)$ ]]; then
    echo "<ul><li>${BASH_REMATCH[1]}</li></ul>" >> "$output_file"
  # Handle blockquotes
  elif [[ $line =~ ^>\ (.*)$ ]]; then
    echo "<blockquote>${BASH_REMATCH[1]}</blockquote>" >> "$output_file"
  # Handle horizontal rules
  elif [[ $line == "---" ]]; then
    echo "<hr>" >> "$output_file"
  # Handle paragraph breaks
  elif [[ -z $line ]]; then
    echo "<br>" >> "$output_file"
  # Regular text
  else
    # Basic inline formatting
    # Bold
    line=${line//\*\*([^\*]*)\*\*/<strong>\1<\/strong>}
    # Italic
    line=${line//\*([^\*]*)\*/<em>\1<\/em>}
    # Code
    line=${line//\`([^\`]*)\`/<code>\1<\/code>}
    # Links [text](url)
    line=${line//\[([^\]]*)\]\(([^\)]*)\)/<a href="\2">\1<\/a>}
    
    echo "<p>$line</p>" >> "$output_file"
  fi
done

# Close the HTML document
cat >> "$output_file" << EOF
  </main>
  
  <hr>
  <footer>
    <p><a href="index.html">← back to home</a></p>
  </footer>
</body>
</html>
EOF

echo "Converted '$input_file' to '$output_file'"