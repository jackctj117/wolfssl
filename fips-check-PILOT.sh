#!/bin/bash

# fips-check.sh
# This script checks the current revision of the code against the
# previous release of the FIPS code. While wolfSSL and wolfCrypt
# may be advancing, they must work correctly with the last tested
# copy of our FIPS approved code.
#
# This should check out all the approved flavors. The command line
# option selects the flavor. The keep option keeps the output
# directory.

# These variables may be overridden on the command line.
set -e # exit any failure

exit_report(){
    echo "Exiting with status $?"
}
trap exit_report EXIT INT

MAKE="${MAKE:-make}"
GIT="${GIT:-git -c advice.detachedHead=false}"
TEST_DIR="${TEST_DIR:-XXX-fips-test}"
case "$TEST_DIR" in
    /*) ;;
    *) TEST_DIR="${PWD}/${TEST_DIR}"
       ;;
esac
FLAVOR="${FLAVOR:-INVALID}"
KEEP="${KEEP:-no}"
MAKECHECK=${MAKECHECK:-yes}
DOCONFIGURE=${DOCONFIGURE:-yes}
DOAUTOGEN=${DOAUTOGEN:-yes}
FIPS_REPO="${FIPS_REPO:-git@github.com:wolfssl/fips.git}"
WOLFSSL_REPO="${WOLFSSL_REPO:-git@github.com:wolfssl/wolfssl.git}"

Usage() {
    cat <<usageText
Usage: $0 [flavor] [keep]
Flavor is one of:
    v5.2.1 (current FIPS 140-3 PILOT submission)
    v5.2.3 (v5.2.1 base with ARMv8 PAA pulled into boundary)
    v5.2.4 (v5.2.3 base with Kernel Module stability in integrity check)
    v5.2.5 (v5.2.3 duplicate, reports a v5.2.5 version)
Keep (default off) retains the temp dir $TEST_DIR for inspection.

Example:
    $0 v5.2.1 keep
usageText
}

while [ "$1" ]; do
  if [ "$1" = 'keep' ]; then KEEP='yes'; else FLAVOR="$1"; fi
  shift
done

echo "Flavor = $FLAVOR"

case "$FLAVOR" in
v5.2.1)
  FIPS_REPO_TAG=v5.2.1-stable
  BASE_TAG=v5.2.1-stable
  MODS_TAG=v5.2.1-stable-OS_Seed-HdrOnly
  FIPS_OPTION='v5'
  FIPS_FILES=(
    "wolfcrypt/src/fips.c:${FIPS_REPO_TAG}"
    "wolfcrypt/src/fips_test.c:${FIPS_REPO_TAG}"
    "wolfcrypt/src/wolfcrypt_first.c:${FIPS_REPO_TAG}"
    "wolfcrypt/src/wolfcrypt_last.c:${FIPS_REPO_TAG}"
    "wolfssl/wolfcrypt/fips.h:${MODS_TAG}"
  )
  WOLFCRYPT_FILES=(
    "wolfcrypt/src/aes.c:${BASE_TAG}"
    "wolfcrypt/src/aes_asm.asm:${BASE_TAG}"
    "wolfcrypt/src/aes_asm.S:${BASE_TAG}"
    "wolfcrypt/src/aes_gcm_asm.S:${BASE_TAG}"
    "wolfcrypt/src/cmac.c:${BASE_TAG}"
    "wolfcrypt/src/dh.c:${BASE_TAG}"
    "wolfcrypt/src/ecc.c:${BASE_TAG}"
    "wolfcrypt/src/hmac.c:${BASE_TAG}"
    "wolfcrypt/src/kdf.c:${BASE_TAG}"
    "wolfcrypt/src/random.c:${BASE_TAG}"
    "wolfcrypt/src/rsa.c:${BASE_TAG}"
    "wolfcrypt/src/sha.c:${BASE_TAG}"
    "wolfcrypt/src/sha256.c:${BASE_TAG}"
    "wolfcrypt/src/sha256_asm.S:${BASE_TAG}"
    "wolfcrypt/src/sha3.c:${BASE_TAG}"
    "wolfcrypt/src/sha512.c:${BASE_TAG}"
    "wolfcrypt/src/sha512_asm.S:${BASE_TAG}"
    "wolfssl/wolfcrypt/aes.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/cmac.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/dh.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/ecc.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/fips_test.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/hmac.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/kdf.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/random.h:${MODS_TAG}"
    "wolfssl/wolfcrypt/rsa.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha256.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha3.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha512.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/aes.h:${BASE_TAG}"
  )
  ;;

# module v5.2.1 base with ARMv8-PAA pulled into module boundary -> v5.2.3
v5.2.3)
  FIPS_REPO_TAG=v5.2.1-stable
  BASE_TAG=v5.2.1-stable
  MODS_TAG=WCv5.2.3-ARMv8-PAA       # tag: both wolfSSL and fips repo
  MODS_TAG_B=WCv5.2.3-ARMv8-PAA-r2  # tag: wolfSSL repo only
  MODS_TAG_C=WCv5.2.3-ARMv8-PAA-r3  # tag: fips repo only
  MODS_TAG_D=WCv5.2.3-STM32-PAA     # tag: wolfSSL repo only
  MODS_TAG_E=WCv5.2.3-ARMv8-PAA-r4  # tag: fips repo only (= r3 + WinCE changes)
  MODS_TAG_F=WCv6.0.0-RC5           # tag: wolfSSL repo for thumb2 + RISCV asm
  MODS_TAG_G=WCv5.2.3-DHGENPUB-r2   # tag: wolfSSL & FIPS repo for DHGENPUB
  MODS_TAG_H=WCv5.2.3-WinThreadLS   # tag: FIPS repo for Windows Thread LS fix //Obsoleted by MODS_TAG_I tag
  MODS_TAG_I=WCv5.2.3-FIPS-MSG      # tag: FIPS repo for FIPS_MSG fix
  MODS_TAG_J=WCv5.2.3-RSA-SWITCH    # tag: wolfSSL repo for RSA CRT/STD method switch
  MODS_TAG_K=WCv5.2.3-WINCE-UPDT    # tag: FIPS repo for WinCE porting changes
  FIPS_OPTION='v5'
  FIPS_FILES=(
    "wolfcrypt/src/fips.c:${MODS_TAG_K}"
    "wolfcrypt/src/fips_test.c:${MODS_TAG}"
    "wolfcrypt/src/wolfcrypt_first.c:${FIPS_REPO_TAG}"
    "wolfcrypt/src/wolfcrypt_last.c:${FIPS_REPO_TAG}"
    "wolfssl/wolfcrypt/fips.h:${MODS_TAG_G}"
  )
  WOLFCRYPT_FILES=(
    "wolfcrypt/src/aes.c:${MODS_TAG_D}"
    "wolfcrypt/src/aes_asm.asm:${BASE_TAG}"
    "wolfcrypt/src/aes_asm.S:${BASE_TAG}"
    "wolfcrypt/src/aes_gcm_asm.S:${BASE_TAG}"
    "wolfcrypt/src/aes_gcm_x86_asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/cmac.c:${BASE_TAG}"
    "wolfcrypt/src/dh.c:${MODS_TAG_G}"
    "wolfcrypt/src/ecc.c:${BASE_TAG}"
    "wolfcrypt/src/hmac.c:${BASE_TAG}"
    "wolfcrypt/src/kdf.c:${BASE_TAG}"
    "wolfcrypt/src/random.c:${MODS_TAG_D}"
    "wolfcrypt/src/rsa.c:${MODS_TAG_J}"
    "wolfcrypt/src/sha.c:${MODS_TAG_D}"
    "wolfcrypt/src/sha256.c:${MODS_TAG_D}"
    "wolfcrypt/src/sha256_asm.S:${BASE_TAG}"
    "wolfcrypt/src/sha3.c:${BASE_TAG}"
    "wolfcrypt/src/sha3_asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/sha512.c:${BASE_TAG}"
    "wolfcrypt/src/sha512_asm.S:${BASE_TAG}"
    "wolfssl/wolfcrypt/cmac.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/dh.h:${MODS_TAG_G}"
    "wolfssl/wolfcrypt/ecc.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/fips_test.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/hmac.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/kdf.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/random.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/rsa.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha256.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha3.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha512.h:${MODS_TAG}"
    "wolfssl/wolfcrypt/aes.h:${MODS_TAG_B}"
    "wolfcrypt/src/port/arm/armv8-32-aes-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-aes-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha256-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha256-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha3-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/armv8-32-sha3-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/armv8-32-sha512-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha512-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-aes.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha256.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha3-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha3-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha512-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha512-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha512.c:${MODS_TAG}"
    "wolfcrypt/src/sp_arm32.c:${MODS_TAG}"
    "wolfcrypt/src/sp_arm64.c:${MODS_TAG}"
    "wolfcrypt/src/sp_armthumb.c:${MODS_TAG}"
    "wolfcrypt/src/sp_c32.c:${MODS_TAG}"
    "wolfcrypt/src/sp_c64.c:${MODS_TAG}"
    "wolfcrypt/src/sp_cortexm.c:${MODS_TAG}"
    "wolfcrypt/src/sp_x86_64_asm.asm:${MODS_TAG}"
    "wolfcrypt/src/sp_x86_64_asm.S:${MODS_TAG}"
    "wolfcrypt/src/sp_x86_64.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/thumb2-aes-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-aes-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha256-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha256-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha3-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha3-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha512-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha512-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/riscv/riscv-64-sha256.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/riscv/riscv-64-sha3.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/riscv/riscv-64-sha512.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/st/stm32.c:${MODS_TAG_D}"
  )
  ;;

v5.2.4)
  FIPS_REPO_TAG=v5.2.1-stable
  BASE_TAG=v5.2.1-stable
  MODS_TAG=WCv5.2.3-ARMv8-PAA       # tag: both wolfSSL and fips repo
  MODS_TAG_B=WCv5.2.3-ARMv8-PAA-r2  # tag: wolfSSL repo only
  MODS_TAG_C=WCv5.2.3-ARMv8-PAA-r3  # tag: fips repo only
  MODS_TAG_D=WCv5.2.3-STM32-PAA     # tag: wolfSSL repo only
  MODS_TAG_E=WCv5.2.3-ARMv8-PAA-r4  # tag: fips repo only (= r3 + WinCE changes)
  MODS_TAG_F=WCv6.0.0-RC5           # tag: wolfSSL repo for thumb2 + RISCV asm
  MODS_TAG_G=WCv5.2.3-DHGENPUB-r2   # tag: wolfSSL & FIPS repo for DHGENPUB
  MODS_TAG_H=WCv5.2.3-WinThreadLS   # tag: FIPS repo for Windows Thread LS fix //Obsoleted by MODS_TAG_I tag
  MODS_TAG_I=WCv5.2.3-FIPS-MSG      # tag: FIPS repo for FIPS_MSG fix
  MODS_TAG_J=WCv5.2.3-RSA-SWITCH    # tag: wolfSSL repo for RSA CRT/STD method switch
  MODS_TAG_K=WCv5.2.3-WINCE-UPDT    # tag: FIPS repo for WinCE porting changes
  # tag: WCv5.2.4-KRNL-CHKIN - wolfssl and fips: Linux KM Updates to stabilize integrity check in Kernel mode
  # tag: WCv5.2.4-KRNL-CHKIN-r2 - fips: Version set, checks for USE_CERT_BUFFERS before forcefully setting
  # tag: WCv5.2.4-KRNL-CHKIN-r3 - fips: Linux KM fixes for optest
  # tag: WCv5.2.4-KRNL-CHKIN-r4 - wolfssl: fix wc_RNG_GenerateBlock() to use seedCb;
  #                               fips: refactor to use wolfSSL_Atomic_Int, WOLFSSL_KERNEL_MODE,
  #                                     WC_SYM_RELOC_TABLES, and WC_PIE_INDIRECT_SYM()
  MODS_TAG_L=WCv5.2.4-KRNL-CHKIN-r5 # wolfssl: smallstackcache expansion in random.[ch], ecc.c, sha256.c, and sha512.c;
  #                                            backport HmacKeyCopyHash(), and provisions for cached RNG in rsa.[ch].
  #                                   fips: fix leaks and missing context inits in KATs.
  MODS_TAG_M=WCv5.2.4-KRNL-CHKIN-r6 # fips: export conTestFailure for kernel optest;
  #                                   fips: catch and handle errors from SHA calls in RsaSignPKCS1v15_KnownAnswerTest().
  FIPS_OPTION='v5'
  FIPS_FILES=(
    "wolfcrypt/src/fips.c:${MODS_TAG_M}"
    "wolfcrypt/src/fips_test.c:${MODS_TAG_M}"
    "wolfcrypt/src/wolfcrypt_first.c:${FIPS_REPO_TAG}"
    "wolfcrypt/src/wolfcrypt_last.c:${FIPS_REPO_TAG}"
    "wolfssl/wolfcrypt/fips.h:${MODS_TAG_M}"
  )
  WOLFCRYPT_FILES=(
    "wolfcrypt/src/aes.c:${MODS_TAG_D}"
    "wolfcrypt/src/aes_asm.asm:${BASE_TAG}"
    "wolfcrypt/src/aes_asm.S:${BASE_TAG}"
    "wolfcrypt/src/aes_gcm_asm.S:${BASE_TAG}"
    "wolfcrypt/src/aes_gcm_x86_asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/cmac.c:${BASE_TAG}"
    "wolfcrypt/src/dh.c:${MODS_TAG_G}"
    "wolfcrypt/src/ecc.c:${MODS_TAG_L}"
    "wolfcrypt/src/hmac.c:${MODS_TAG_L}"
    "wolfcrypt/src/kdf.c:${MODS_TAG_L}"
    "wolfcrypt/src/random.c:${MODS_TAG_L}"
    "wolfcrypt/src/rsa.c:${MODS_TAG_L}"
    "wolfcrypt/src/sha.c:${MODS_TAG_D}"
    "wolfcrypt/src/sha256.c:${MODS_TAG_L}"
    "wolfcrypt/src/sha256_asm.S:${BASE_TAG}"
    "wolfcrypt/src/sha3.c:${BASE_TAG}"
    "wolfcrypt/src/sha3_asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/sha512.c:${MODS_TAG_L}"
    "wolfcrypt/src/sha512_asm.S:${BASE_TAG}"
    "wolfssl/wolfcrypt/cmac.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/dh.h:${MODS_TAG_G}"
    "wolfssl/wolfcrypt/ecc.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/fips_test.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/hmac.h:${MODS_TAG_L}"
    "wolfssl/wolfcrypt/kdf.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/random.h:${MODS_TAG_L}"
    "wolfssl/wolfcrypt/rsa.h:${MODS_TAG_L}"
    "wolfssl/wolfcrypt/sha.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha256.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha3.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha512.h:${MODS_TAG}"
    "wolfssl/wolfcrypt/aes.h:${MODS_TAG_B}"
    "wolfcrypt/src/port/arm/armv8-32-aes-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-aes-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha256-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha256-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha3-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/armv8-32-sha3-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/armv8-32-sha512-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha512-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-aes.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha256.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha3-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha3-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha512-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha512-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha512.c:${MODS_TAG}"
    "wolfcrypt/src/sp_arm32.c:${MODS_TAG}"
    "wolfcrypt/src/sp_arm64.c:${MODS_TAG}"
    "wolfcrypt/src/sp_armthumb.c:${MODS_TAG}"
    "wolfcrypt/src/sp_c32.c:${MODS_TAG}"
    "wolfcrypt/src/sp_c64.c:${MODS_TAG}"
    "wolfcrypt/src/sp_cortexm.c:${MODS_TAG}"
    "wolfcrypt/src/sp_x86_64_asm.asm:${MODS_TAG}"
    "wolfcrypt/src/sp_x86_64_asm.S:${MODS_TAG}"
    "wolfcrypt/src/sp_x86_64.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/thumb2-aes-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-aes-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha256-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha256-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha3-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha3-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha512-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha512-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/riscv/riscv-64-sha256.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/riscv/riscv-64-sha3.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/riscv/riscv-64-sha512.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/st/stm32.c:${MODS_TAG_D}"
  )
  ;;

# essentially just v5.2.3, but going through a seperate submission
v5.2.5)
  FIPS_REPO_TAG=v5.2.1-stable
  BASE_TAG=v5.2.1-stable
  MODS_TAG=WCv5.2.3-ARMv8-PAA       # tag: both wolfSSL and fips repo
  MODS_TAG_B=WCv5.2.3-ARMv8-PAA-r2  # tag: wolfSSL repo only
  MODS_TAG_C=WCv5.2.3-ARMv8-PAA-r3  # tag: fips repo only
  MODS_TAG_D=WCv5.2.3-STM32-PAA     # tag: wolfSSL repo only
  MODS_TAG_E=WCv5.2.3-ARMv8-PAA-r4  # tag: fips repo only (= r3 + WinCE changes)
  MODS_TAG_F=WCv6.0.0-RC5           # tag: wolfSSL repo for thumb2 + RISCV asm
  MODS_TAG_G=WCv5.2.3-DHGENPUB-r2   # tag: wolfSSL & FIPS repo for DHGENPUB
  MODS_TAG_H=WCv5.2.3-WinThreadLS   # tag: FIPS repo for Windows Thread LS fix //Obsoleted by MODS_TAG_I tag
  MODS_TAG_I=WCv5.2.3-FIPS-MSG      # tag: FIPS repo for FIPS_MSG fix
  MODS_TAG_J=WCv5.2.3-RSA-SWITCH    # tag: wolfSSL repo for RSA CRT/STD method switch
  MODS_TAG_K=WCv5.2.3-WINCE-UPDT    # tag: FIPS repo for WinCE porting changes
  MODS_TAG_L=WCv5.2.5-stable        # tag: FIPS repo for v5.2.5 version update
  FIPS_OPTION='v5'
  FIPS_FILES=(
    "wolfcrypt/src/fips.c:${MODS_TAG_L}"
    "wolfcrypt/src/fips_test.c:${MODS_TAG}"
    "wolfcrypt/src/wolfcrypt_first.c:${FIPS_REPO_TAG}"
    "wolfcrypt/src/wolfcrypt_last.c:${FIPS_REPO_TAG}"
    "wolfssl/wolfcrypt/fips.h:${MODS_TAG_G}"
  )
  WOLFCRYPT_FILES=(
    "wolfcrypt/src/aes.c:${MODS_TAG_D}"
    "wolfcrypt/src/aes_asm.asm:${BASE_TAG}"
    "wolfcrypt/src/aes_asm.S:${BASE_TAG}"
    "wolfcrypt/src/aes_gcm_asm.S:${BASE_TAG}"
    "wolfcrypt/src/aes_gcm_x86_asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/cmac.c:${BASE_TAG}"
    "wolfcrypt/src/dh.c:${MODS_TAG_G}"
    "wolfcrypt/src/ecc.c:${BASE_TAG}"
    "wolfcrypt/src/hmac.c:${BASE_TAG}"
    "wolfcrypt/src/kdf.c:${BASE_TAG}"
    "wolfcrypt/src/random.c:${MODS_TAG_D}"
    "wolfcrypt/src/rsa.c:${MODS_TAG_J}"
    "wolfcrypt/src/sha.c:${MODS_TAG_D}"
    "wolfcrypt/src/sha256.c:${MODS_TAG_D}"
    "wolfcrypt/src/sha256_asm.S:${BASE_TAG}"
    "wolfcrypt/src/sha3.c:${BASE_TAG}"
    "wolfcrypt/src/sha3_asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/sha512.c:${BASE_TAG}"
    "wolfcrypt/src/sha512_asm.S:${BASE_TAG}"
    "wolfssl/wolfcrypt/cmac.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/dh.h:${MODS_TAG_G}"
    "wolfssl/wolfcrypt/ecc.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/fips_test.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/hmac.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/kdf.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/random.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/rsa.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha256.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha3.h:${BASE_TAG}"
    "wolfssl/wolfcrypt/sha512.h:${MODS_TAG}"
    "wolfssl/wolfcrypt/aes.h:${MODS_TAG_B}"
    "wolfcrypt/src/port/arm/armv8-32-aes-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-aes-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha256-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha256-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha3-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/armv8-32-sha3-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/armv8-32-sha512-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-32-sha512-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-aes.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha256.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha3-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha3-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha512-asm.S:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha512-asm_c.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/armv8-sha512.c:${MODS_TAG}"
    "wolfcrypt/src/sp_arm32.c:${MODS_TAG}"
    "wolfcrypt/src/sp_arm64.c:${MODS_TAG}"
    "wolfcrypt/src/sp_armthumb.c:${MODS_TAG}"
    "wolfcrypt/src/sp_c32.c:${MODS_TAG}"
    "wolfcrypt/src/sp_c64.c:${MODS_TAG}"
    "wolfcrypt/src/sp_cortexm.c:${MODS_TAG}"
    "wolfcrypt/src/sp_x86_64_asm.asm:${MODS_TAG}"
    "wolfcrypt/src/sp_x86_64_asm.S:${MODS_TAG}"
    "wolfcrypt/src/sp_x86_64.c:${MODS_TAG}"
    "wolfcrypt/src/port/arm/thumb2-aes-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-aes-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha256-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha256-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha3-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha3-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha512-asm_c.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/arm/thumb2-sha512-asm.S:${MODS_TAG_F}"
    "wolfcrypt/src/port/riscv/riscv-64-sha256.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/riscv/riscv-64-sha3.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/riscv/riscv-64-sha512.c:${MODS_TAG_F}"
    "wolfcrypt/src/port/st/stm32.c:${MODS_TAG_D}"
  )
  ;;


*)
  Usage
  exit 1
esac

# checkout_files takes an array of pairs of file paths and git tags to
# checkout. It will check to see if mytag exists and if not will make that
# tag a branch.
function checkout_files() {
    local name
    local tag
    for file_entry in "$@"
    do
        name=${file_entry%%:*}
        tag=${file_entry#*:}
        if ! $GIT rev-parse -q --verify "my$tag" >/dev/null
        then
            $GIT branch --no-track "my$tag" "$tag"
        fi
        $GIT checkout "my$tag" -- "$name"
    done
}

# copy_fips_files takes an array of pairs of file paths and git tags to
# checkout. It will check to see if mytag exists and if now will make that
# tag a branch.  It breaks the filepath apart into file name and path, then
# copies it from the file from the fips directory to the path.
function copy_fips_files() {
    local name
    local bname
    local dname
    local tag
    for file_entry in "$@"
    do
        name=${file_entry%%:*}
        tag=${file_entry#*:}
        bname=$(basename "$name")
        dname=$(dirname "$name")
        if ! $GIT rev-parse -q --verify "my$tag" >/dev/null
        then
            $GIT branch --no-track "my$tag" "$tag"
        fi
        $GIT checkout "my$tag" -- "$bname"
        cp "$bname" "../$dname"
    done
}

# Note, it would be cleaner to compute the tag lists using associative arrays,
# but those were introduced in bash-4.  It's more important to maintain backward
# compatibility here.

declare -a WOLFCRYPT_TAGS_NEEDED_UNSORTED WOLFCRYPT_TAGS_NEEDED
if [ ${#WOLFCRYPT_FILES[@]} -gt 0 ]; then
    for file_entry in "${WOLFCRYPT_FILES[@]}"; do
        WOLFCRYPT_TAGS_NEEDED_UNSORTED+=("${file_entry#*:}")
    done
    while IFS= read -r tag; do WOLFCRYPT_TAGS_NEEDED+=("$tag"); done < <(IFS=$'\n'; sort -u <<< "${WOLFCRYPT_TAGS_NEEDED_UNSORTED[*]}")
    if [ "${#WOLFCRYPT_TAGS_NEEDED[@]}" = "0" ]; then
        echo "Error -- missing wolfCrypt tags." 1>&2
        exit 1
    fi
fi

declare -a FIPS_TAGS_NEEDED_UNSORTED FIPS_TAGS_NEEDED
for file_entry in "${FIPS_FILES[@]}"; do
    FIPS_TAGS_NEEDED_UNSORTED+=("${file_entry#*:}")
done
while IFS= read -r tag; do FIPS_TAGS_NEEDED+=("$tag"); done < <(IFS=$'\n'; sort -u <<< "${FIPS_TAGS_NEEDED_UNSORTED[*]}")
if [ "${#FIPS_TAGS_NEEDED[@]}" = "0" ]; then
    echo "Error -- missing FIPS tags." 1>&2
    exit 1
fi

if [ ${#WOLFCRYPT_TAGS_NEEDED[@]} -gt 0 ]; then
    echo "wolfCrypt tag$( [[ ${#WOLFCRYPT_TAGS_NEEDED[@]} != "1" ]] && echo -n 's'):"

    # Only use shallow fetch if the repo already has shallow branches, to avoid
    # tainting full repos with shallow objects.
    if [ -f .git/shallow ]; then
        shallow_args=(--depth 1)
    else
        shallow_args=()
    fi

    for tag in "${WOLFCRYPT_TAGS_NEEDED[@]}"; do
        if $GIT describe --long --exact-match "$tag" 2>/dev/null; then
            continue
        fi
        if ! $GIT fetch "${shallow_args[@]}" "$WOLFSSL_REPO" tag "$tag"; then
            echo "Can't fetch wolfCrypt tag: $tag" 1>&2
            exit 1
        fi
        # Make sure the tag is associated:
        $GIT fetch origin refs/tags/"$tag":refs/tags/"$tag"
    done
fi

if ! $GIT clone --shared . "$TEST_DIR"; then
    echo "fips-check: Couldn't clone current working directory." 1>&2
    exit 1
fi

# If there is a FIPS repo under the parent directory, leverage that:
if [ -d ../fips/.git ]; then
    pushd ../fips 1>/dev/null

    # Only use shallow fetch if the repo already has shallow branches, to avoid
    # tainting full repos with shallow objects.
    if [ -f .git/shallow ]; then
        shallow_args=(--depth 1)
    else
        shallow_args=()
    fi

    echo "FIPS tag$( [[ ${#FIPS_TAGS_NEEDED[@]} != "1" ]] && echo -n 's'):"
    for tag in "${FIPS_TAGS_NEEDED[@]}"; do
        if [ "$tag" = "master" ]; then
            # master is handled specially below.
            continue
        fi
        if $GIT describe --long --exact-match "$tag" 2>/dev/null; then
            continue
        fi
        if ! $GIT fetch "${shallow_args[@]}" "$FIPS_REPO" tag "$tag"; then
            echo "Can't fetch FIPS tag: $tag" 1>&2
            exit 1
        fi
        # Make sure the tag is associated:
        $GIT fetch origin refs/tags/"$tag":refs/tags/"$tag"
    done

    # The current tooling for the FIPS tests is in the master branch and must be
    # checked out here.
    if ! $GIT clone --shared --branch master . "${TEST_DIR}/fips"; then
        echo "fips-check: Couldn't clone current working directory." 1>&2
        exit 1
    fi

    popd 1>/dev/null

    # Make sure master is up-to-date:
    pushd "${TEST_DIR}/fips" 1>/dev/null
    if ! $GIT pull "$FIPS_REPO" master; then
        echo "Can't refresh master FIPS tag" 1>&2
        exit 1
    fi

    popd 1>/dev/null
fi

pushd "$TEST_DIR" 1>/dev/null

if [ ! -d fips ]; then
    # The current tooling for the FIPS tests is in the master branch and must be
    # checked out here.
    if ! $GIT clone --depth 1 --branch master "$FIPS_REPO" fips; then
        echo "fips-check: Couldn't check out FIPS repository."
        exit 1
    fi

    pushd fips 1>/dev/null
    echo "FIPS tag$( [[ ${#FIPS_TAGS_NEEDED[@]} != "1" ]] && echo -n 's'):"
    for tag in "${FIPS_TAGS_NEEDED[@]}"; do
        if [ ! -z "$tag" ]; then
            if [ "$tag" = "master" ]; then
                # master was just cloned fresh from $FIPS_REPO above.
                continue
            fi
            if $GIT describe --long --exact-match --always "$tag"; then
                continue
            fi
            # The FIPS repo here is an ephemeral clone, so we can safely use
            # shallow fetch unconditionally.
            if ! $GIT fetch --depth 1 "$FIPS_REPO" tag "$tag"; then
                echo "Can't fetch FIPS tag: $tag" 1>&2
                exit 1
            fi
            # Make sure the tag is associated:
            $GIT fetch origin refs/tags/"$tag":refs/tags/"$tag"
        fi
    done
    popd 1>/dev/null
fi

checkout_files "${WOLFCRYPT_FILES[@]}"
pushd fips
copy_fips_files "${FIPS_FILES[@]}"
popd

# run the make test
./autogen.sh
./configure --enable-fips=$FIPS_OPTION

if ! $MAKE
then
    echo 'fips-check: Make failed. Debris left for analysis.'
    exit 3
fi
./fips-hash.sh

if ! $MAKE check
then
    echo 'fips-check: Test failed. Debris left for analysis.'
    exit 3
fi

# Clean up
popd
if [ "$KEEP" = 'no' ];
then
    rm -rf "$TEST_DIR"
fi

set +e # stop exiting on any failure
