#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv){

    FILE* out;
    int lines, samples;
    char* filename = (char*) malloc(50 * sizeof(char));
    int min = -100;
    int max = 100;

    if(argc != 3 && argc != 5){
        printf("Correct Input: [lines] [samples] | Optional: [min] [max]\n");
        exit(1);
    }

    lines = strtol(argv[1], NULL, 10);
    samples = strtol(argv[2], NULL, 10);
    if(argc == 5){
        if(max <= min){
            printf("Error: max <= min!\n");
            exit(1);
        }
        min = strtol(argv[3], NULL, 10);
        max = strtol(argv[4], NULL, 10);
    }

    sprintf(filename, "./test_files/input%dx%d.inp", lines, samples);

    srand(0);
    out = fopen(filename, "w+");
    for(int i = 0; i < lines; i++){
        for(int j = 0; j < samples; j++){

            fprintf(out, "%d", min + rand() % (max-min));

            if(j  < samples -1) 
                fprintf(out, "\t ");
    
        }
        fprintf(out, "\n");
    }

    fclose(out);
    free(filename);

    return 0;
}