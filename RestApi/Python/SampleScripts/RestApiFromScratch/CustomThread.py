# Created by PyCharm Community Edition
# User: atudor
# Date: 1/15/2016
# Time: 12:29 PM
# Project: untitled
# File: Threads
# Email: atudor@ixiacom.com
# Company: IXIA 2016

import threading


class CustomThread(threading.Thread):
    def __init__(self, target, *args):
        self._target = target
        self._args = args
        threading.Thread.__init__(self)

    def run(self):
        self._target(*self._args)


class Test(object):

    # Example usage
    def func(self, data, key):
        print "func was called : data=%s; key=%s" % (str(data), str(key))

    def func1(self, data, key):
        print "func1 was called : data=%s; key=%s" % (str(data), str(key))

    def func2(self, data, key):
        print data + key

    def main(self):
        t1 = CustomThread(self.func, [1, 2], 6)
        t2 = CustomThread(self.func1, [2, 5], 6)
        t3 = CustomThread(self.func2, 5, 6)

        t1.start()
        t2.start()
        t3.start()
        t1.join()
        t2.join()
        t3.join()

if __name__ == "__main__":
    test = Test()
    test.main()

