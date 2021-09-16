echo updating Example header
cd bin
copy example.78b.a78 example_concerto.bin
7800header -o -f a78info.cfg "example_concerto.bin"
cd ..