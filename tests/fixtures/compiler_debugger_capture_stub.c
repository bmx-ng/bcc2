#if defined(__APPLE__)
/* Keep the production debugger's fullscreen guard from terminating this
   headless interactive regression before it can consume scripted commands. */
unsigned int CGDisplayIsCaptured(unsigned int display_id) {
    (void)display_id;
    return 0;
}
#else
typedef int bcc2_debugger_capture_stub_translation_unit;
#endif
