int bcc2_native_counter = 41;
void *bcc2_native_buffer = 0;

static int bcc2_native_add(int left, int right) {
	return left + right;
}

int (*bcc2_native_callback)(int, int) = bcc2_native_add;
