class SpectranextSdk < Formula
  desc "SDK for developing Spectranext and Spectranet applications"
  homepage "https://github.com/spectranext/spectranext-sdk"
  version "0.1.0"
  license :cannot_represent

  url "https://github.com/spectranext/spectranext-sdk/releases/download/0.1.0/spectranext-sdk-0.1.0-macos-arm64.tar.gz"
  sha256 "3932b462d9fad03dee5a9bb9ab62b057379c67b88d74e8e27e19e5751e9c0419"

  depends_on "cmake"
  depends_on "python@3.14"

  resource "z88dk" do
    url "http://nightly.z88dk.org/z88dk-osx-20260530-a996c99f3d-24825.zip"
    version "20260530-a996c99f3d-24825"
    sha256 "13161d4e84f0fdd9c653610147416c536050461f95c55a464fd14c2047423c51"
  end

  def install
    libexec.install Dir["*"]

    rm_r libexec/"venv" if (libexec/"venv").directory?

    unless (libexec/"vendor/wheels").directory?
      odie "Release archive must include vendor/wheels for offline Python dependency installation"
    end

    system Formula["python@3.14"].opt_bin/"python3.14", "-m", "venv", libexec/"venv"
    system libexec/"venv/bin/python", "-m", "pip", "install",
           "--no-index",
           "--find-links=#{libexec}/vendor/wheels",
           "-r", libexec/"requirements.txt"

    resource("z88dk").stage do
      extracted = Pathname.glob("*")
      z88dk_root = extracted.find { |path| path.directory? && (path/"bin/zcc").exist? }
      z88dk_root ||= Pathname.pwd if (Pathname.pwd/"bin/zcc").exist?
      odie "z88dk resource did not contain bin/zcc" unless z88dk_root

      (libexec/"z88dk").install z88dk_root.children
    end

    sdk_bin = libexec/"bin"
    z88dk_bin = libexec/"z88dk/bin"

    %w[spx spectranext-detect.sh gdbserver-none.sh makebas].each do |tool|
      next unless (sdk_bin/tool).exist?

      (bin/tool).write <<~EOS
        #!/bin/bash
        exec "#{sdk_bin/tool}" "$@"
      EOS
      chmod 0755, bin/tool
    end

    if z88dk_bin.directory?
      z88dk_bin.children.each do |tool|
        next unless tool.file? && tool.executable?

        (bin/tool.basename).write <<~EOS
          #!/bin/bash
          export PATH="#{z88dk_bin}:$PATH"

          ZCCCFG_PATH="#{libexec}/z88dk/share/z88dk/lib/config"
          if [ ! -d "$ZCCCFG_PATH" ]; then
            if [ -d "#{libexec}/z88dk/lib/config" ]; then
              ZCCCFG_PATH="#{libexec}/z88dk/lib/config"
            elif [ -d "#{libexec}/z88dk/config" ]; then
              ZCCCFG_PATH="#{libexec}/z88dk/config"
            fi
          fi

          export ZCCCFG="$ZCCCFG_PATH"
          export ZCCTARGET="zx"
          export SPECTRANEXT_SDK_PATH="#{libexec}"
          export SPECTRANEXT_INCLUDE_DIR="#{libexec}/include"
          if [ -f "#{libexec}/z88dk/support/cmake/Toolchain-zcc.cmake" ]; then
            export SPECTRANEXT_TOOLCHAIN="#{libexec}/z88dk/support/cmake/Toolchain-zcc.cmake"
          fi

          exec "#{tool}" "$@"
        EOS
        chmod 0755, bin/tool.basename
      end
    end

    (bin/"spectranext-sdk-env").write <<~EOS
      #!/bin/bash
      printf '%s\\n' 'source "#{libexec}/source.sh"'
    EOS
    chmod 0755, bin/"spectranext-sdk-env"
  end

  def caveats
    <<~EOS
      To use the SDK environment in your shell, run:
        source "#{libexec}/source.sh"

      Or add it to your shell profile:
        echo 'source "#{libexec}/source.sh"' >> ~/.zshrc

      To configure CMake projects with the z88dk toolchain:
        cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE="#{opt_libexec}/z88dk/support/cmake/Toolchain-zcc.cmake"

      To print that command from scripts:
        spectranext-sdk-env
    EOS
  end

  test do
    assert_path_exists libexec/"source.sh"
    assert_path_exists libexec/"cmake/spectranext_sdk_import.cmake"

    system bin/"spx", "--help"
    system bin/"zcc", "+zx", "-v"
  end
end
