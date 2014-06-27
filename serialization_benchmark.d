/**
 * An implementation of the mini serialization benchmark also available for
 * C++ and Java.
 */

import std.datetime : AutoStart, StopWatch;
import std.math : PI;
import std.stdio;
import thrift.transport.memory;
import thrift.transport.range;
import DebugProtoTest_types;

version (ThriftBenchmarkBinary) {
  import thrift.protocol.binary;
  alias protocolConstructor = tBinaryProtocol;
} else version (ThriftBenchmarkCompact) {
  import thrift.protocol.compact;
  alias protocolConstructor = tCompactProtocol;
} else version (ThriftBenchmarkJson) {
  import thrift.protocol.json;
  alias protocolConstructor = tJsonProtocol;
} else static assert(0, "Define a ThriftBenchmark<Protocol> version.");


void main() {
  auto buf = new TMemoryBuffer;
  enum ITERATIONS = 1_000_000;

  {
    auto ooe = OneOfEach();
    ooe.im_true   = true;
    ooe.im_false  = false;
    ooe.a_bite    = 0x7f;
    ooe.integer16 = 27_000;
    ooe.integer32 = 1 << 24;
    ooe.integer64 = 6_000_000_000;
    ooe.double_precision = PI;
    ooe.some_characters = "JSON THIS! \"\1";
    ooe.zomg_unicode = "\xd7\n\a\t";
    ooe.base64 = "\1\2\3\255";

    auto prot = protocolConstructor(buf);
    auto sw = StopWatch(AutoStart.yes);
    foreach (i; 0 .. ITERATIONS) {
      buf.reset(120);
      ooe.write(prot);
    }
    sw.stop();

    auto msecs = sw.peek().msecs;
    writefln("Write: %s ms (%s kHz)", msecs, ITERATIONS / msecs);
  }

  auto data = buf.getContents().dup;

  {
    auto readBuf = tInputRangeTransport(data);
    auto prot = protocolConstructor(readBuf);
    auto ooe = OneOfEach();

    auto sw = StopWatch(AutoStart.yes);
    foreach (i; 0 .. ITERATIONS) {
      readBuf.reset(data);
      ooe.read(prot);
    }
    sw.stop();

    auto msecs = sw.peek().msecs;
    writefln(" Read: %s ms (%s kHz)", msecs, ITERATIONS / msecs);
  }
}
