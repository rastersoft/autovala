#ª/bin/bash
for file in *.md; do
    cat header.html > "../doc/`basename $file .md`"
    markdown "$file" >> "../doc/`basename $file .md`"
    cat footer.html >> "../doc/`basename $file .md`"
done
