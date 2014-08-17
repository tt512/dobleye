import derelict.opengl3.gl;
import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import std.stdio;
import std.c.stdlib;
import std.file;
import std.string;
import std.conv;

/**
 * Shader class
 */
class Shader {
  private:
    uint id_;
    string sourceCode;

  public:
    @property {
      uint id() { return id_; }
    }
    this(GLenum type) {
      id_ = glCreateShader(type);
    }
    ~this() {
      glDeleteShader(id_);
    }

    /**
     * source glsl code from a file
     * Params: filePath = is glsl file path
     */
    void source(string filePath) {
      sourceCode = cast(string)read(filePath);
    }

    /**
     * Compile shader
     */
    void compile() {
      // Compile Shader
      writeln("Compiling shader...");
      const char *p = sourceCode.ptr;
      glShaderSource(id_, 1, &p, null);
      glCompileShader(id_);

      // Check Shader
      int compileStatus, logLen;
      glGetShaderiv(id_, GL_COMPILE_STATUS, &compileStatus);
      glGetShaderiv(id_, GL_INFO_LOG_LENGTH, &logLen);

      if (logLen > 1) {
        char[] log = new char[](logLen);
        glGetShaderInfoLog(id, logLen, null, log.ptr);
        writeln("Program link log:\n", to!string(log));
      }
    }
}

class Program {
  private:
    uint id_;
  public:
    @property {
      uint id() { return id_; }
    }
    this() {
      id_ = glCreateProgram();
    }

    void attachShader(uint shader) {
      glAttachShader(id_, shader);
    }

    void link() {
      glLinkProgram(id_);

      // Check the program
      int ret, logLen;
      glGetProgramiv(id_, GL_LINK_STATUS, &ret);
      glGetProgramiv(id_, GL_INFO_LOG_LENGTH, &logLen);

      if (logLen > 1)
      {
        char[] log = new char[](logLen);
        glGetProgramInfoLog(id_, logLen, null, log.ptr);
        writeln("Program link log:\n", to!string(log));
      }
    }
}

class Buffer {
  GLuint buffer;
  alias buffer this;

  this(T)(T[] data) {
    glGenBuffers(1, &buffer);
    setData(data);
  }

  void bind() {
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
  }

  void setData(T)(T[] data) {
    bind();
    glBufferData(GL_ARRAY_BUFFER,
        T.sizeof * data.length,
        data.ptr, GL_STATIC_DRAW);
  }
}
int main() {
  // Load OpenGL versions 1.0 and 1.1.
  DerelictGL3.load();

  // Create an OpenGL context with another library (like SDL 2 or GLFW 3)
  DerelictGLFW3.load();
  // Initialise GLFW
  if( !glfwInit() )
  {
    stderr.writeln("Failed to initialize GLFW" );
    return -1;
  }

  glfwWindowHint(GLFW_SAMPLES, 4);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);


  // Open a window and create its OpenGL context
  auto window = glfwCreateWindow( 1024, 768, "Tutorial 02 - Red triangle", null, null);
  if( window == null ){
    stderr.writeln("Failed to open GLFW window.");
    glfwTerminate();
    return -1;
  }
  glfwMakeContextCurrent(window);

  // Load versions 1.2+ and all supported ARB and EXT extensions.
  DerelictGL3.reload();

  // Ensure we can capture the escape key being pressed below
  glfwSetInputMode(window, GLFW_STICKY_KEYS, GL_TRUE);

  // Dark blue background
  glClearColor(0.0, 0.0, 0.4, 0.0);

  // Create and compile our GLSL program from the shaders
  auto vShader = new Shader(GL_VERTEX_SHADER);
  vShader.source("SimpleVertexShader.vertexshader");
  vShader.compile();

  auto fShader = new Shader(GL_FRAGMENT_SHADER);
  fShader.source("SimpleFragmentShader.fragmentshader");
  fShader.compile();

  auto program = new Program();
  program.attachShader(vShader.id);
  program.attachShader(fShader.id);
  program.link();

  uint programID = program.id;
  // Get a handle for our buffers
  GLuint vertexPosition_modelspaceID = glGetAttribLocation(programID, "vertexPosition_modelspace");

  float[] g_vertex_buffer_data = [
    -1.0, -1.0, 0.0,
    1.0, -1.0, 0.0,
    0.0,  1.0, 0.0,
  ];

  GLuint vertexbuffer;
  glGenBuffers(1, &vertexbuffer);
  glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
  glBufferData(GL_ARRAY_BUFFER, float.sizeof * g_vertex_buffer_data.length, g_vertex_buffer_data.ptr, GL_STATIC_DRAW);

  do{

    // Clear the screen
    glClear( GL_COLOR_BUFFER_BIT );

    // Use our shader
    glUseProgram(programID);

    // 1rst attribute buffer : vertices
    glEnableVertexAttribArray(vertexPosition_modelspaceID);
    glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
    glVertexAttribPointer(
        vertexPosition_modelspaceID, // The attribute we want to configure
        3,                  // size
        GL_FLOAT,           // type
        GL_FALSE,           // normalized?
        0,                  // stride
        cast(void*)0            // array buffer offset
        );

    // Draw the triangle !
    glDrawArrays(GL_TRIANGLES, 0, 3); // 3 indices starting at 0 -> 1 triangle

    glDisableVertexAttribArray(vertexPosition_modelspaceID);

    // Swap buffers
    glfwSwapBuffers(window);
    glfwPollEvents();

  } // Check if the ESC key was pressed or the window was closed
  while( glfwGetKey(window, GLFW_KEY_ESCAPE ) != GLFW_PRESS &&
      glfwWindowShouldClose(window) == 0 );


  // Cleanup VBO
  glDeleteBuffers(1, &vertexbuffer);
  glDeleteProgram(programID);

  // Close OpenGL window and terminate GLFW
  glfwTerminate();

  return 0;
}
