all: init build

build: bin/nbfc-stat

init:
	@if [ ! -d "bin" ]; then \
		echo "Creating bin directory..."; \
		mkdir -p bin; \
	fi

bin/nbfc-stat: nbfc-stat.c
	@echo "Compiling nbfc-stat..."
	gcc -o bin/nbfc-stat nbfc-stat.c

clean:
	rm -rf bin
