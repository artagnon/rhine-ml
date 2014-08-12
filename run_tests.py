#!/usr/bin/env python

from os import walk
from subprocess import Popen, PIPE

class colors:
    HEADER = '\033[95m'
    OK = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    END = '\033[0m'

def get_test_files():
    filelist = []
    for (dirpath, dirnames, filenames) in walk("tests/"):
        filelist.extend(filenames)
    return filelist

def run():
    tests = get_test_files()
    no_tests = len(tests)
    no_successes = 0

    print colors.HEADER
    print "--------------------------"
    print "RUNNING TESTS..."
    print "--------------------------"
    print colors.END


    for filename in tests:
        if filename.startswith("output.") or not filename.endswith(".rht"):
            no_tests -= 1
            continue
        contents = open("tests/"+filename).read().split("---")
        test_input = contents[0].strip()
        expected_output = "---".join(contents[1:]).strip()

        p = Popen(["./rhine", "-"], stdin=PIPE, stdout=PIPE, stderr=PIPE)
        stdout, stderr = p.communicate(test_input)
        stdout = stdout.lower()
        stderr = stderr.lower()

        if stderr.find(expected_output) >= 0 or stdout.find(expected_output) >= 0:
            no_successes += 1
            print "%s %s: SUCCESS%s" % (colors.OK, filename, colors.END)
        else:
            f = open('tests/output.'+filename,'w')
            f.write(stdout+stderr)
            f.close()
            print "%s %s: FAILED (output written to tests/)" % (colors.FAIL, filename)

    if no_successes == no_tests:
        print colors.OK
    else:
        print colors.FAIL


    print "--------------------------"
    print "TOTAL TESTS: %i" % no_tests
    print "SUCCESSES: %i" % no_successes
    print "FAILS: %i" % (no_tests - no_successes)
    print "--------------------------"
    print colors.END




if __name__ == "__main__":
    run()


