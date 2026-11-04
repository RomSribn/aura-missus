// Minimal Hermes JSI host: evaluates each JS file given on argv in ONE runtime
// (so a polyfill file can be loaded before a test file). Installs print().
#include <hermes/hermes.h>
#include <jsi/jsi.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <memory>

using namespace facebook;

static std::string readFile(const char *p) {
  std::ifstream f(p, std::ios::binary);
  if (!f) { std::cerr << "cannot open " << p << "\n"; exit(2); }
  std::stringstream ss; ss << f.rdbuf(); return ss.str();
}

int main(int argc, char **argv) {
  if (argc < 2) { std::cerr << "usage: host file.js [file2.js ...]\n"; return 2; }
  auto cfg = ::hermes::vm::RuntimeConfig::Builder()
                 .withMicrotaskQueue(true)
                 .build();
  std::unique_ptr<facebook::hermes::HermesRuntime> rt = facebook::hermes::makeHermesRuntime(cfg);
  jsi::Runtime &r = *rt;
  auto printFn = jsi::Function::createFromHostFunction(
      r, jsi::PropNameID::forAscii(r, "print"), 1,
      [](jsi::Runtime &rr, const jsi::Value &, const jsi::Value *args, size_t n) -> jsi::Value {
        for (size_t i = 0; i < n; ++i) {
          if (i) std::cout << " ";
          std::cout << args[i].toString(rr).utf8(rr);
        }
        std::cout << "\n" << std::flush;
        return jsi::Value::undefined();
      });
  r.global().setProperty(r, "print", printFn);
  for (int i = 1; i < argc; ++i) {
    std::string a = argv[i];
    if (a.size() < 3 || a.substr(a.size() - 3) != ".js") continue; // skip NSUserDefaults args like -AppleLanguages
    std::string src = readFile(argv[i]);
    try {
      r.evaluateJavaScript(std::make_shared<jsi::StringBuffer>(src), argv[i]);
      r.drainMicrotasks();
    } catch (const jsi::JSError &e) {
      std::cout << "JSError in " << argv[i] << ": " << e.getMessage() << "\n" << e.getStack() << "\n";
      return 1;
    } catch (const std::exception &e) {
      std::cout << "std::exception in " << argv[i] << ": " << e.what() << "\n";
      return 1;
    }
  }
  return 0;
}
