#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <sys/time.h>
#include <vector>
#include <limits>

#define THREADS 512

#ifdef __cplusplus
extern "C"
{
#endif

using namespace std; 

__global__ void insertion_sort(float *device_data, int *device_start, int *device_offset){
    int start=device_start[blockIdx.x];
    int offset=device_offset[blockIdx.x];
    device_data += start;
    float tmp;
    int i, j, k;

    // Perform insertion sort
    for (i = 0; i < offset-1; i++) {
        j = i + 1;
        k = i;

        // find the smallest element
        for (j = i+1; j < offset; j++)
            if (device_data[k] > device_data[j])
                k = j;

        // swap elements
        tmp=device_data[k];
        device_data[k]=device_data[i];
        device_data[i]=tmp;
    }
}

std::vector<vector <float> > get_buckets(int bucket_count) {
	std::vector<vector <float> > buckets;
    int i;
    for (i = 0;i < bucket_count; i++) {
        std::vector<float> list;
        buckets.push_back(list);
    }
    return buckets;
}

float get_max(int number_of_elements, float *data) {
	float max = -std::numeric_limits<float>::infinity();
    int i;
    for (i = 0; i < number_of_elements; i++)
        if(max < data[i])
            max = data[i];
    return max;
}

std::vector<vector <float> > assign_bucket(int number_of_elements, float *data, float max, int bucket_count) {
	std::vector<vector <float> > buckets = get_buckets(bucket_count);
	int index;
    int i;
	for (i = 0 ;i < number_of_elements; i++){
        index = int((bucket_count*data[i])/(max+0.01)); // same as used in pthreads
        buckets[index].push_back(data[i]);
    }
    return buckets;
}

void bucket_sort(std::vector<vector <float> > buckets, int bucket_count, 
					float *data, int *start, int *offset) {
	int size, i, j;
	int index = 0;
	for (i=0; i < bucket_count; i++) {
		size = buckets[i].size();
		offset[i]=int(buckets[i].size());
		start[i]=int(index);
		for (j=0; j < size; j++){
			data[index]=float(buckets[i][j]);
			index++;
		}
	}
}

int cuda_sort(int number_of_elements, float *a)
{
	int bucket_count;
	float *data, max;
	int *start, *offset;
	std::vector<vector <float> > buckets;

	// get bucket count - best performance found at this configuration
    bucket_count=number_of_elements/64;

	// find max element
    max = get_max(number_of_elements, a);

    // assign elements to appropriate buckets 
    buckets = assign_bucket(number_of_elements, a, max, bucket_count);

    // perform bucket sort on the array by arranging the bucket elements
	data = (float *)malloc(number_of_elements*sizeof(float));
	start = (int *)malloc(bucket_count*sizeof(int));
	offset = (int *)malloc(bucket_count*sizeof(int));
	bucket_sort(buckets, bucket_count, data, start, offset);

	// prepare for running insertion sorting on GPU in parallel
    float *device_data;
    int *device_start, *device_offset;
    cudaMalloc((void **) &device_data, sizeof(float)*number_of_elements);
    cudaMemcpy(device_data, data, sizeof(float)*number_of_elements, cudaMemcpyHostToDevice);
    cudaMalloc((void **) &device_start, sizeof(int)*bucket_count);
    cudaMemcpy(device_start, start, sizeof(int)*bucket_count, cudaMemcpyHostToDevice);
    cudaMalloc((void **) &device_offset, sizeof(int)*bucket_count);
    cudaMemcpy(device_offset, offset, sizeof(int)*bucket_count, cudaMemcpyHostToDevice);

    // run sorting on GPU
    dim3 dimGrid(bucket_count);
    dim3 dimBlock(1);
    insertion_sort<<<dimGrid, dimBlock>>>(device_data, device_start, device_offset);

    // copy results
    cudaMemcpy(a, device_data, sizeof(float)*number_of_elements, cudaMemcpyDeviceToHost);

    // free back to heap
    cudaFree(device_data);
    cudaFree(device_start);
    cudaFree(device_offset);
    free(data);
    free(start);
    free(offset);
	return 0;
}

#ifdef __cplusplus
}
#endif

