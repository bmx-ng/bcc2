#include <stdint.h>

#include "canonical_list.h"

int main(void) {
    BBSTRING first = (BBSTRING)(uintptr_t)1;
    BBSTRING second = (BBSTRING)(uintptr_t)2;
    struct bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_obj *list;

    initialize_file1(first);
    initialize_file2(second);
    list = list1;

    if (list != list1 || list == list2) {
        return 1;
    }
    if (bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_First(list) != first) {
        return 2;
    }
    if (bmx_gen_Collections_Core_TArrayList_string_f4809e2216dc6ea913a2ff7649253794_First(list2) != second) {
        return 3;
    }
    return 0;
}
