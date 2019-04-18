#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <sys/time.h>
#include <pthread.h>
#include "mysort.h"
#include <limits>
using namespace std;

struct listNode {
	float val;
	struct listNode *nxt;
};

int bucket_size;
struct listNode **heads;
float max = -std::numeric_limits<float>::infinity();
float min = std::numeric_limits<float>::infinity();
int thread_count = 2;
void *bucketSort(void *arg);
struct listNode * insertionSort(struct listNode *list);

int pthread_sort(int num_of_elements, float *data)
{
    struct listNode *node;

    // find max and min element
    for(int i = 0; i < num_of_elements; i++)
    {
        if(max < data[i]){
        	max = data[i];
	}
	if (min > data[i]) {
		min = data[i];
	}
    }
    // printf("Max %f, min %f\n", max, min); 
    if (min == max) {
    	return 0;
    }       

    // create and initialise buckets  
    bucket_size = num_of_elements/2;
    // printf("Create and initialise buckets\n"); 
    heads = (struct listNode **)malloc(sizeof(struct listNode*) * num_of_elements);
	for(int i = 0; i < bucket_size; i++)
		heads[i] = NULL;

    // make bucket nodes
    // printf("Make bucket nodes for each data element\n");
    float width = max-min+0.00001;
    node = NULL;    
	for(int i = 0; i < num_of_elements; i++) {
		node = (struct listNode *) malloc(sizeof(struct listNode));
		int index = int((bucket_size*data[i])/(max+0.01));
		node->val = data[i];
		node->nxt = heads[index];
		heads[index] = node;
	}

	// printf("Creating threads\n");
	// create Threads and wait for them to complete
	pthread_t pthread[2];
	int *arg = (int*)malloc(sizeof(int)*thread_count);
	for (int i =0; i < thread_count; i++){
		arg[i] = i;
	}
	for (int i =0; i < thread_count; i++){
		pthread_create(&pthread[i], NULL, bucketSort, (void*)(arg+i)); 
	}
	for (int i =0; i < thread_count; i++){
		pthread_join(pthread[i], NULL);
	}
	free(arg);

	// combine solution
    node = NULL;    
	// printf("Combine solution\n");
	int i = 0;
	for(int b = 0; b < bucket_size; b++) {
		node = heads[b];
		while(node != NULL) {
			data[i] = node->val;
			i++;
			node = node->nxt;
		}
	}
	return 0;
}

void* bucketSort(void *arg)
{	 	
	int *flag = (int *)arg;
	// printf("bucketSort called %d\n", *flag);
	int start = *flag * bucket_size;
	int end = start + bucket_size;
	for(int i = start; i < end; i++) {
		heads[i] = insertionSort(heads[i]);
	}
	// printf("bucketSort completed %d\n", *flag);
}

struct listNode * insertionSort(struct listNode *head) {
	// NULL check
	if (head == NULL) {
		return head;
	}

	struct listNode *ptr, *prev, *node, *cur, *dummy;		
	ptr = head;
	dummy = (struct listNode *) malloc(sizeof(struct listNode));
	dummy->val = -std::numeric_limits<float>::infinity();
	dummy->nxt = NULL;

	// perform insertion sort on the list
	while (ptr != NULL) {
		// extract node
		node = ptr;
		ptr = ptr->nxt;
		node->nxt = NULL;

		// find position to insert the node
		prev = dummy;
		cur = dummy->nxt;

		while (cur != NULL && cur->val < node->val) {
			prev = cur;
			cur = cur->nxt;
		}

		// insert into the sorted list
		node->nxt = prev->nxt;
		prev->nxt = node;
	}

	head = dummy->nxt;
	free(dummy);
	return head;
}
