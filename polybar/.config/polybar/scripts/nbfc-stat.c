// Note: This tool relies on nbfc service .json output (make sure the service is running)
// Check /run/nbfc_service.pid (if the process is not running, then restart the service using: sudo nbfc restart)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// uses NoteBook FanControl CLI Client state file to determine the current fan status (works on hp6550b)
#define STATE_FILE "/run/nbfc_service.state.json"

void extract_value(const char *data, const char *key, char *result) {
    char *start = strstr(data, key);
    if (start) {
        start = strchr(start, ':');
        if (start) {
            start++;
            while (*start == ' ') start++; // Skip spaces
            char *end = strchr(start, ',');
            if (!end) {
                end = strchr(start, '}');
            }
            if (end) {
                strncpy(result, start, end - start);
                result[end - start] = '\0';
            }
        }
    }
}

int main() {
    FILE *file = fopen(STATE_FILE, "r");
    if (!file) {
        printf("?nbfc?\n");
        return 1;
    }

    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);

    char *data = malloc(length + 1);
    if (data) {
        fread(data, 1, length, file);
        data[length] = '\0'; // Null-terminate the string
    }
    fclose(file);

    char temperature[16] = "?";
    char current_speed[16] = "?";

    extract_value(data, "\"temperature\"", temperature);
    extract_value(data, "\"current_speed\"", current_speed);

    printf("%s°C[%s%%]\n", temperature, current_speed);

    free(data);
    return 0;
}
