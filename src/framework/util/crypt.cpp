/*
 * Copyright (c) 2010-2014 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "crypt.h"
#include <framework/stdext/math.h>
#include <framework/core/logger.h>
#include <framework/core/resourcemanager.h>
#include <framework/platform/platform.h>
#include <framework/core/application.h>

 // [Fix] Removed Boost UUID includes
#include <random>
#include <sstream>
#include <iomanip>
#include <vector>

#ifndef USE_GMP
#include <openssl/rsa.h>
#include <openssl/sha.h>
#include <openssl/md5.h>
#include <openssl/bn.h>
#include <openssl/err.h>
#endif

static const std::string base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static inline bool is_base64(unsigned char c) { return (isalnum(c) || (c == '+') || (c == '/')); }

Crypt g_crypt;

Crypt::Crypt()
{
#ifdef USE_GMP
    mpz_init(m_p);
    mpz_init(m_q);
    mpz_init(m_d);
    mpz_init(m_e);
    mpz_init(m_n);
#else
    m_rsa = RSA_new();
#endif
}

Crypt::~Crypt()
{
#ifdef USE_GMP
    mpz_clear(m_p);
    mpz_clear(m_q);
    mpz_clear(m_n);
    mpz_clear(m_d);
    mpz_clear(m_e);
#else
    RSA_free(m_rsa);
#endif
}

std::string Crypt::base64Encode(const std::string& decoded_string)
{
    std::string ret;
    int i = 0;
    int j = 0;
    uint8 char_array_3[3];
    uint8 char_array_4[4];
    int pos = 0;
    int len = decoded_string.size();

    while (len--) {
        char_array_3[i++] = decoded_string[pos++];
        if (i == 3) {
            char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
            char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
            char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
            char_array_4[3] = char_array_3[2] & 0x3f;

            for (i = 0; (i < 4); i++)
                ret += base64_chars[char_array_4[i]];
            i = 0;
        }
    }

    if (i) {
        for (j = i; j < 3; j++)
            char_array_3[j] = '\0';

        char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
        char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
        char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
        char_array_4[3] = char_array_3[2] & 0x3f;

        for (j = 0; (j < i + 1); j++)
            ret += base64_chars[char_array_4[j]];

        while ((i++ < 3))
            ret += '=';
    }

    return ret;
}

std::string Crypt::base64Decode(const std::string& encoded_string)
{
    int len = encoded_string.size();
    int i = 0;
    int j = 0;
    int in_ = 0;
    uint8 char_array_4[4], char_array_3[3];
    std::string ret;

    while (len-- && (encoded_string[in_] != '=') && is_base64(encoded_string[in_])) {
        char_array_4[i++] = encoded_string[in_]; in_++;
        if (i == 4) {
            for (i = 0; i < 4; i++)
                char_array_4[i] = base64_chars.find(char_array_4[i]);

            char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
            char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
            char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

            for (i = 0; (i < 3); i++)
                ret += char_array_3[i];
            i = 0;
        }
    }

    if (i) {
        for (j = i; j < 4; j++)
            char_array_4[j] = 0;

        for (j = 0; j < 4; j++)
            char_array_4[j] = base64_chars.find(char_array_4[j]);

        char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
        char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
        char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

        for (j = 0; (j < i - 1); j++)
            ret += char_array_3[j];
    }

    return ret;
}

std::string Crypt::xorCrypt(const std::string& buffer, const std::string& key)
{
    std::string out;
    out.resize(buffer.size());
    register size_t i, j = 0;
    for (i = 0; i < buffer.size(); ++i) {
        out[i] = buffer[i] ^ key[j++];
        if (j >= key.size())
            j = 0;
    }
    return out;
}

// [Fix] Reimplemented using standard C++ random instead of Boost
std::string Crypt::genUUID()
{
    static std::random_device rd;
    static std::mt19937 gen(rd());
    static std::uniform_int_distribution<> dis(0, 15);
    static std::uniform_int_distribution<> dis2(8, 11);

    std::stringstream ss;
    ss << std::hex;
    for (int i = 0; i < 8; i++) ss << dis(gen);
    ss << "-";
    for (int i = 0; i < 4; i++) ss << dis(gen);
    ss << "-4"; // version 4
    for (int i = 0; i < 3; i++) ss << dis(gen);
    ss << "-";
    ss << dis2(gen); // variant
    for (int i = 0; i < 3; i++) ss << dis(gen);
    ss << "-";
    for (int i = 0; i < 12; i++) ss << dis(gen);
    return ss.str();
}

bool Crypt::setMachineUUID(std::string uuidstr)
{
    if (uuidstr.empty())
        return false;
    uuidstr = _decrypt(uuidstr, false);
    if (uuidstr.length() != 16)
        return false;
    // [Fix] Store directly in string
    m_machineUUID = uuidstr;
    return true;
}

std::string Crypt::getMachineUUID()
{
    // [Fix] Check if string is empty
    if (m_machineUUID.empty()) {
        // Generate random 16 bytes for machine UUID
        static std::random_device rd;
        static std::mt19937 gen(rd());
        static std::uniform_int_distribution<> dis(0, 255);
        m_machineUUID.resize(16);
        for (int i = 0; i < 16; ++i)
            m_machineUUID[i] = static_cast<char>(dis(gen));
    }
    return _encrypt(m_machineUUID, false);
}

std::string Crypt::getCryptKey(bool useMachineUUID)
{
    std::string uuid;
    if (useMachineUUID) {
        uuid = m_machineUUID;
    }
    else {
        // nil UUID (16 bytes of zeros)
        uuid = std::string(16, 0);
    }

    // [Fix] Use std::hash or simple string combination instead of boost::uuid name_generator
    std::string seedData = uuid + g_app.getCompactName() + g_platform.getCPUName() + g_platform.getOSName() + g_resources.getUserDir();

    // Use the existing SHA1 encode function to generate a key from the seed data
    // This replicates the behavior of generating a hash from the UUID+Name
    std::string hash = sha1Encode(seedData, false);

    // We need a raw key, SHA1 string is hex, let's just use the hash string itself or a hash of it
    std::size_t str_hash = std::hash<std::string>{}(hash);

    std::string key;
    key.assign((const char*)&str_hash, sizeof(str_hash));
    return key;
}

std::string Crypt::_encrypt(const std::string& decrypted_string, bool useMachineUUID)
{
    std::string tmp = "0000" + decrypted_string;
    uint32 sum = stdext::adler32((const uint8*)decrypted_string.c_str(), decrypted_string.size());
    stdext::writeULE32((uint8*)&tmp[0], sum);
    std::string encrypted = base64Encode(xorCrypt(tmp, getCryptKey(useMachineUUID)));
    return encrypted;
}

std::string Crypt::_decrypt(const std::string& encrypted_string, bool useMachineUUID)
{
    std::string decoded = base64Decode(encrypted_string);
    std::string tmp = xorCrypt(base64Decode(encrypted_string), getCryptKey(useMachineUUID));
    if (tmp.length() >= 4) {
        uint32 readsum = stdext::readULE32((const uint8*)tmp.c_str());
        std::string decrypted_string = tmp.substr(4);
        uint32 sum = stdext::adler32((const uint8*)decrypted_string.c_str(), decrypted_string.size());
        if (readsum == sum)
            return decrypted_string;
    }
    return std::string();
}

std::string Crypt::md5Encode(const std::string& decoded_string, bool upperCase)
{
    MD5_CTX c;
    MD5_Init(&c);
    MD5_Update(&c, decoded_string.c_str(), decoded_string.length());

    uint8_t md[MD5_DIGEST_LENGTH];
    MD5_Final(md, &c);

    char output[(MD5_DIGEST_LENGTH << 1) + 1];
    for (int32_t i = 0; i < (int32_t)sizeof(md); ++i)
        sprintf(output + (i << 1), "%.2X", md[i]);

    std::string result = output;
    if (upperCase)
        return result;

    std::transform(result.begin(), result.end(), result.begin(), tolower);
    return result;
}

std::string Crypt::sha1Encode(const std::string& decoded_string, bool upperCase)
{
    SHA_CTX c;
    SHA1_Init(&c);
    SHA1_Update(&c, decoded_string.c_str(), decoded_string.length());

    uint8_t md[SHA_DIGEST_LENGTH];
    SHA1_Final(md, &c);

    char output[(SHA_DIGEST_LENGTH << 1) + 1];
    for (int32_t i = 0; i < (int32_t)sizeof(md); ++i)
        sprintf(output + (i << 1), "%.2X", md[i]);

    std::string result = output;
    if (upperCase)
        return result;

    std::transform(result.begin(), result.end(), result.begin(), tolower);
    return result;
}

std::string Crypt::sha256Encode(const std::string& decoded_string, bool upperCase)
{
    SHA256_CTX c;
    SHA256_Init(&c);
    SHA256_Update(&c, decoded_string.c_str(), decoded_string.length());

    uint8_t md[SHA256_DIGEST_LENGTH];
    SHA256_Final(md, &c);

    char output[(SHA256_DIGEST_LENGTH << 1) + 1];
    for (int32_t i = 0; i < (int32_t)sizeof(md); ++i)
        sprintf(output + (i << 1), "%.2X", md[i]);

    std::string result = output;
    if (upperCase)
        return result;

    std::transform(result.begin(), result.end(), result.begin(), tolower);
    return result;
}

std::string Crypt::sha512Encode(const std::string& decoded_string, bool upperCase)
{
    SHA512_CTX c;
    SHA512_Init(&c);
    SHA512_Update(&c, decoded_string.c_str(), decoded_string.length());

    uint8_t md[SHA512_DIGEST_LENGTH];
    SHA512_Final(md, &c);

    char output[(SHA512_DIGEST_LENGTH << 1) + 1];
    for (int32_t i = 0; i < (int32_t)sizeof(md); ++i)
        sprintf(output + (i << 1), "%.2X", md[i]);

    std::string result = output;
    if (upperCase)
        return result;

    std::transform(result.begin(), result.end(), result.begin(), tolower);
    return result;
}

void Crypt::rsaSetPublicKey(const std::string& n, const std::string& e)
{
#ifdef USE_GMP
    mpz_set_str(m_n, n.c_str(), 10);
    mpz_set_str(m_e, e.c_str(), 10);
#else
#if OPENSSL_VERSION_NUMBER < 0x10100005L
    BN_dec2bn(&m_rsa->n, n.c_str());
    BN_dec2bn(&m_rsa->e, e.c_str());
    // clear rsa cache
    if (m_rsa->_method_mod_n) {
        BN_MONT_CTX_free(m_rsa->_method_mod_n);
        m_rsa->_method_mod_n = nullptr;
    }
#else
    BIGNUM* bn = nullptr, * be = nullptr;
    BN_dec2bn(&bn, n.c_str());
    BN_dec2bn(&be, e.c_str());
    RSA_set0_key(m_rsa, bn, be, nullptr);
#endif
#endif
}

void Crypt::rsaSetPrivateKey(const std::string& p, const std::string& q, const std::string& d)
{
#ifdef USE_GMP
    mpz_set_str(m_p, p.c_str(), 10);
    mpz_set_str(m_q, q.c_str(), 10);
    mpz_set_str(m_d, d.c_str(), 10);

    // n = p * q
    mpz_mul(n, p, q);
#else
#if OPENSSL_VERSION_NUMBER < 0x10100005L
    BN_dec2bn(&m_rsa->p, p.c_str());
    BN_dec2bn(&m_rsa->q, q.c_str());
    BN_dec2bn(&m_rsa->d, d.c_str());
    // clear rsa cache
    if (m_rsa->_method_mod_p) {
        BN_MONT_CTX_free(m_rsa->_method_mod_p);
        m_rsa->_method_mod_p = nullptr;
    }
    if (m_rsa->_method_mod_q) {
        BN_MONT_CTX_free(m_rsa->_method_mod_q);
        m_rsa->_method_mod_q = nullptr;
    }
#else
    BIGNUM* bp = nullptr, * bq = nullptr, * bd = nullptr;
    BN_dec2bn(&bp, p.c_str());
    BN_dec2bn(&bq, q.c_str());
    BN_dec2bn(&bd, d.c_str());
    RSA_set0_key(m_rsa, nullptr, nullptr, bd);
    RSA_set0_factors(m_rsa, bp, bq);
#endif
#endif
}

bool Crypt::rsaEncrypt(unsigned char* msg, int size)
{
    if (size != rsaGetSize())
        return false;

#ifdef USE_GMP
    mpz_t c, m;
    mpz_init(c);
    mpz_init(m);
    mpz_import(m, size, 1, 1, 0, 0, msg);

    // c = m^e mod n
    mpz_powm(c, m, m_e, m_n);

    size_t count = (mpz_sizeinbase(m, 2) + 7) / 8;
    memset((char*)msg, 0, size - count);
    mpz_export((char*)msg + (size - count), nullptr, 1, 1, 0, 0, c);

    mpz_clear(c);
    mpz_clear(m);

    return true;
#else
    return RSA_public_encrypt(size, msg, msg, m_rsa, RSA_NO_PADDING) != -1;
#endif
}

bool Crypt::rsaDecrypt(unsigned char* msg, int size)
{
    if (size != rsaGetSize())
        return false;

#ifdef USE_GMP
    mpz_t c, m;
    mpz_init(c);
    mpz_init(m);
    mpz_import(c, size, 1, 1, 0, 0, msg);

    // m = c^d mod n
    mpz_powm(m, c, m_d, m_n);

    size_t count = (mpz_sizeinbase(m, 2) + 7) / 8;
    memset((char*)msg, 0, size - count);
    mpz_export((char*)msg + (size - count), nullptr, 1, 1, 0, 0, m);

    mpz_clear(c);
    mpz_clear(m);

    return true;
#else
    return RSA_private_decrypt(size, msg, msg, m_rsa, RSA_NO_PADDING) != -1;
#endif
}

int Crypt::rsaGetSize()
{
#ifdef USE_GMP
    size_t count = (mpz_sizeinbase(m_n, 2) + 7) / 8;
    return ((int)count / 128) * 128;
#else
    return RSA_size(m_rsa);
#endif
}
