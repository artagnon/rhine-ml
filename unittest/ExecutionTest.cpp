#include "rhine/Ast.h"
#include "rhine/Support.h"
#include "rhine/Toplevel.h"
#include "gtest/gtest.h"

#ifdef _MSC_VER
#include <io.h>
#define popen _popen 
#define pclose _pclose
#define stat _stat 
#define dup _dup
#define dup2 _dup2
#define fileno _fileno
#define close _close
#define pipe _pipe
#define read _read
#define eof _eof
#else
#include <unistd.h>
#endif
#include <fcntl.h>
#include <stdio.h>
#include <thread>
#include <mutex>

class StdCapture
{
public:
    StdCapture()
    {
        // make stdout & stderr streams unbuffered
        // so that we don't need to flush the streams
        // before capture and after capture 
        // (fflush can cause a deadlock if the stream is currently being 
        setvbuf(stdout,NULL,_IONBF,0);
        setvbuf(stderr,NULL,_IONBF,0);
    }

    void BeginCapture()
    {
        if (m_capturing)
            return;

        secure_pipe(m_pipe);
        m_oldStdOut = secure_dup(fileno(stdout));
        m_oldStdErr = secure_dup(fileno(stderr));
        secure_dup2(m_pipe[WRITE],fileno(stdout));
        secure_dup2(m_pipe[WRITE],fileno(stderr));
        m_capturing = true;
#ifndef _MSC_VER
        secure_close(m_pipe[WRITE]);
#endif
    }

    bool IsCapturing()
    {
        return m_capturing;
    }

    void EndCapture()
    {
        if (!m_capturing)
            return;

        m_captured.clear();
        secure_dup2(m_oldStdOut, fileno(stdout));
        secure_dup2(m_oldStdErr, fileno(stderr));

        const int bufSize = 1025;
        char buf[bufSize];
        int bytesRead = 0;
        do
        {
            bytesRead = 0;
#ifdef _MSC_VER
            if (!eof(m_pipe[READ]))
                bytesRead = read(m_pipe[READ], buf, bufSize-1);
#else
            bytesRead = read(m_pipe[READ], buf, bufSize-1);
#endif
            if (bytesRead > 0)
            {
                buf[bytesRead] = 0;
                m_captured += buf;
            }
        } while (bytesRead == (bufSize-1));

        secure_close(m_oldStdOut);
        secure_close(m_oldStdErr);
        secure_close(m_pipe[READ]);
#ifdef _MSC_VER
        secure_close(m_pipe[WRITE]);
#endif
        m_capturing = false;
    }
    std::string GetCapture()
    {
        return m_captured;
    }
private:
    enum PIPES { READ, WRITE };

    int secure_dup(int src)
    {
        int ret = -1;
        do
        {
             ret = dup(src);
        } while (ret < 0);
        return ret;
    }
    void secure_pipe(int * pipes)
    {
        int ret = -1;
        do
        {
#ifdef _MSC_VER
            ret = pipe(pipes, 65536, O_BINARY);
#else
            ret = pipe(pipes) == -1;
#endif
        } while (ret < 0);
    }
    void secure_dup2(int src, int dest)
    {
        int ret = -1;
        do
        {
             ret = dup2(src,dest);
        } while (ret < 0);
    }

    void secure_close(int & fd)
    {
        int ret = -1;
        do
        {
             ret = close(fd);
        } while (ret < 0);

        fd = -1;
    }

    int m_pipe[2];
    int m_oldStdOut;
    int m_oldStdErr;
    bool m_capturing;
    std::string m_captured;
};

void EXPECT_OUTPUT(std::string SourcePrg, std::string ExpectedOut)
{
  auto Handle = rhine::jitFacade(SourcePrg, false, true);
  auto CaptureH = StdCapture();
  CaptureH.BeginCapture();
  Handle();
  CaptureH.EndCapture();
  std::string ActualOut = CaptureH.GetCapture();
  EXPECT_STREQ(ExpectedOut.c_str(), ActualOut.c_str());
}

TEST(Execution, PrintfConstantInt) {
  std::string SourcePrg =
    "defun main [bar] {"
    "  printf \"43\";"
    "}";
  std::string ExpectedOut = "43";
  EXPECT_OUTPUT(SourcePrg, ExpectedOut);
}
