package e.debugger;

/**
 * Defines the debugging commands that are available to the DebuggerServer, and
 * that can be invoked by connecting to the server port and passing the method
 * name and any arguments to the server.
 */
public interface DebuggerCommandHandler {
    
    public void setBreakpoint(String className, String lineNumber);
    public void clearBreakpoint(String className, String lineNumber);
    public void setExceptionBreakpoint(String exceptionClassName);
    public void clearExceptionBreakpoint(String exceptionClassName);
    
    public void suspend();
    public void resume();
    
    public void step();
    public void stepInto();
    public void stepOut();
    
    /**
     * Connect to a running VM that was started with -agentlib:jdwp=transport=dt_socket,server=y
     * @param address the socket address the target is listening on.
     */
    public void connect(String address);
}
