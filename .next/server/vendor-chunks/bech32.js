"use strict";
/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file with attached SourceMaps in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
exports.id = "vendor-chunks/bech32";
exports.ids = ["vendor-chunks/bech32"];
exports.modules = {

/***/ "(ssr)/./node_modules/bech32/dist/index.js":
/*!*******************************************!*\
  !*** ./node_modules/bech32/dist/index.js ***!
  \*******************************************/
/***/ ((__unused_webpack_module, exports) => {

eval("\nObject.defineProperty(exports, \"__esModule\", ({ value: true }));\nexports.bech32m = exports.bech32 = void 0;\nconst ALPHABET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';\nconst ALPHABET_MAP = {};\nfor (let z = 0; z < ALPHABET.length; z++) {\n    const x = ALPHABET.charAt(z);\n    ALPHABET_MAP[x] = z;\n}\nfunction polymodStep(pre) {\n    const b = pre >> 25;\n    return (((pre & 0x1ffffff) << 5) ^\n        (-((b >> 0) & 1) & 0x3b6a57b2) ^\n        (-((b >> 1) & 1) & 0x26508e6d) ^\n        (-((b >> 2) & 1) & 0x1ea119fa) ^\n        (-((b >> 3) & 1) & 0x3d4233dd) ^\n        (-((b >> 4) & 1) & 0x2a1462b3));\n}\nfunction prefixChk(prefix) {\n    let chk = 1;\n    for (let i = 0; i < prefix.length; ++i) {\n        const c = prefix.charCodeAt(i);\n        if (c < 33 || c > 126)\n            return 'Invalid prefix (' + prefix + ')';\n        chk = polymodStep(chk) ^ (c >> 5);\n    }\n    chk = polymodStep(chk);\n    for (let i = 0; i < prefix.length; ++i) {\n        const v = prefix.charCodeAt(i);\n        chk = polymodStep(chk) ^ (v & 0x1f);\n    }\n    return chk;\n}\nfunction convert(data, inBits, outBits, pad) {\n    let value = 0;\n    let bits = 0;\n    const maxV = (1 << outBits) - 1;\n    const result = [];\n    for (let i = 0; i < data.length; ++i) {\n        value = (value << inBits) | data[i];\n        bits += inBits;\n        while (bits >= outBits) {\n            bits -= outBits;\n            result.push((value >> bits) & maxV);\n        }\n    }\n    if (pad) {\n        if (bits > 0) {\n            result.push((value << (outBits - bits)) & maxV);\n        }\n    }\n    else {\n        if (bits >= inBits)\n            return 'Excess padding';\n        if ((value << (outBits - bits)) & maxV)\n            return 'Non-zero padding';\n    }\n    return result;\n}\nfunction toWords(bytes) {\n    return convert(bytes, 8, 5, true);\n}\nfunction fromWordsUnsafe(words) {\n    const res = convert(words, 5, 8, false);\n    if (Array.isArray(res))\n        return res;\n}\nfunction fromWords(words) {\n    const res = convert(words, 5, 8, false);\n    if (Array.isArray(res))\n        return res;\n    throw new Error(res);\n}\nfunction getLibraryFromEncoding(encoding) {\n    let ENCODING_CONST;\n    if (encoding === 'bech32') {\n        ENCODING_CONST = 1;\n    }\n    else {\n        ENCODING_CONST = 0x2bc830a3;\n    }\n    function encode(prefix, words, LIMIT) {\n        LIMIT = LIMIT || 90;\n        if (prefix.length + 7 + words.length > LIMIT)\n            throw new TypeError('Exceeds length limit');\n        prefix = prefix.toLowerCase();\n        // determine chk mod\n        let chk = prefixChk(prefix);\n        if (typeof chk === 'string')\n            throw new Error(chk);\n        let result = prefix + '1';\n        for (let i = 0; i < words.length; ++i) {\n            const x = words[i];\n            if (x >> 5 !== 0)\n                throw new Error('Non 5-bit word');\n            chk = polymodStep(chk) ^ x;\n            result += ALPHABET.charAt(x);\n        }\n        for (let i = 0; i < 6; ++i) {\n            chk = polymodStep(chk);\n        }\n        chk ^= ENCODING_CONST;\n        for (let i = 0; i < 6; ++i) {\n            const v = (chk >> ((5 - i) * 5)) & 0x1f;\n            result += ALPHABET.charAt(v);\n        }\n        return result;\n    }\n    function __decode(str, LIMIT) {\n        LIMIT = LIMIT || 90;\n        if (str.length < 8)\n            return str + ' too short';\n        if (str.length > LIMIT)\n            return 'Exceeds length limit';\n        // don't allow mixed case\n        const lowered = str.toLowerCase();\n        const uppered = str.toUpperCase();\n        if (str !== lowered && str !== uppered)\n            return 'Mixed-case string ' + str;\n        str = lowered;\n        const split = str.lastIndexOf('1');\n        if (split === -1)\n            return 'No separator character for ' + str;\n        if (split === 0)\n            return 'Missing prefix for ' + str;\n        const prefix = str.slice(0, split);\n        const wordChars = str.slice(split + 1);\n        if (wordChars.length < 6)\n            return 'Data too short';\n        let chk = prefixChk(prefix);\n        if (typeof chk === 'string')\n            return chk;\n        const words = [];\n        for (let i = 0; i < wordChars.length; ++i) {\n            const c = wordChars.charAt(i);\n            const v = ALPHABET_MAP[c];\n            if (v === undefined)\n                return 'Unknown character ' + c;\n            chk = polymodStep(chk) ^ v;\n            // not in the checksum?\n            if (i + 6 >= wordChars.length)\n                continue;\n            words.push(v);\n        }\n        if (chk !== ENCODING_CONST)\n            return 'Invalid checksum for ' + str;\n        return { prefix, words };\n    }\n    function decodeUnsafe(str, LIMIT) {\n        const res = __decode(str, LIMIT);\n        if (typeof res === 'object')\n            return res;\n    }\n    function decode(str, LIMIT) {\n        const res = __decode(str, LIMIT);\n        if (typeof res === 'object')\n            return res;\n        throw new Error(res);\n    }\n    return {\n        decodeUnsafe,\n        decode,\n        encode,\n        toWords,\n        fromWordsUnsafe,\n        fromWords,\n    };\n}\nexports.bech32 = getLibraryFromEncoding('bech32');\nexports.bech32m = getLibraryFromEncoding('bech32m');\n//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiKHNzcikvLi9ub2RlX21vZHVsZXMvYmVjaDMyL2Rpc3QvaW5kZXguanMiLCJtYXBwaW5ncyI6IkFBQWE7QUFDYiw4Q0FBNkMsRUFBRSxhQUFhLEVBQUM7QUFDN0QsZUFBZSxHQUFHLGNBQWM7QUFDaEM7QUFDQTtBQUNBLGdCQUFnQixxQkFBcUI7QUFDckM7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLG9CQUFvQixtQkFBbUI7QUFDdkM7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0Esb0JBQW9CLG1CQUFtQjtBQUN2QztBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLG9CQUFvQixpQkFBaUI7QUFDckM7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSx3QkFBd0Isa0JBQWtCO0FBQzFDO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLHdCQUF3QixPQUFPO0FBQy9CO0FBQ0E7QUFDQTtBQUNBLHdCQUF3QixPQUFPO0FBQy9CO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLHdCQUF3QixzQkFBc0I7QUFDOUM7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EsaUJBQWlCO0FBQ2pCO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBLGNBQWM7QUFDZCxlQUFlIiwic291cmNlcyI6WyJ3ZWJwYWNrOi8vYW5pbWFsX2Nyb3NzaW5nLy4vbm9kZV9tb2R1bGVzL2JlY2gzMi9kaXN0L2luZGV4LmpzPzdhZmEiXSwic291cmNlc0NvbnRlbnQiOlsiJ3VzZSBzdHJpY3QnO1xuT2JqZWN0LmRlZmluZVByb3BlcnR5KGV4cG9ydHMsIFwiX19lc01vZHVsZVwiLCB7IHZhbHVlOiB0cnVlIH0pO1xuZXhwb3J0cy5iZWNoMzJtID0gZXhwb3J0cy5iZWNoMzIgPSB2b2lkIDA7XG5jb25zdCBBTFBIQUJFVCA9ICdxcHpyeTl4OGdmMnR2ZHcwczNqbjU0a2hjZTZtdWE3bCc7XG5jb25zdCBBTFBIQUJFVF9NQVAgPSB7fTtcbmZvciAobGV0IHogPSAwOyB6IDwgQUxQSEFCRVQubGVuZ3RoOyB6KyspIHtcbiAgICBjb25zdCB4ID0gQUxQSEFCRVQuY2hhckF0KHopO1xuICAgIEFMUEhBQkVUX01BUFt4XSA9IHo7XG59XG5mdW5jdGlvbiBwb2x5bW9kU3RlcChwcmUpIHtcbiAgICBjb25zdCBiID0gcHJlID4+IDI1O1xuICAgIHJldHVybiAoKChwcmUgJiAweDFmZmZmZmYpIDw8IDUpIF5cbiAgICAgICAgKC0oKGIgPj4gMCkgJiAxKSAmIDB4M2I2YTU3YjIpIF5cbiAgICAgICAgKC0oKGIgPj4gMSkgJiAxKSAmIDB4MjY1MDhlNmQpIF5cbiAgICAgICAgKC0oKGIgPj4gMikgJiAxKSAmIDB4MWVhMTE5ZmEpIF5cbiAgICAgICAgKC0oKGIgPj4gMykgJiAxKSAmIDB4M2Q0MjMzZGQpIF5cbiAgICAgICAgKC0oKGIgPj4gNCkgJiAxKSAmIDB4MmExNDYyYjMpKTtcbn1cbmZ1bmN0aW9uIHByZWZpeENoayhwcmVmaXgpIHtcbiAgICBsZXQgY2hrID0gMTtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IHByZWZpeC5sZW5ndGg7ICsraSkge1xuICAgICAgICBjb25zdCBjID0gcHJlZml4LmNoYXJDb2RlQXQoaSk7XG4gICAgICAgIGlmIChjIDwgMzMgfHwgYyA+IDEyNilcbiAgICAgICAgICAgIHJldHVybiAnSW52YWxpZCBwcmVmaXggKCcgKyBwcmVmaXggKyAnKSc7XG4gICAgICAgIGNoayA9IHBvbHltb2RTdGVwKGNoaykgXiAoYyA+PiA1KTtcbiAgICB9XG4gICAgY2hrID0gcG9seW1vZFN0ZXAoY2hrKTtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IHByZWZpeC5sZW5ndGg7ICsraSkge1xuICAgICAgICBjb25zdCB2ID0gcHJlZml4LmNoYXJDb2RlQXQoaSk7XG4gICAgICAgIGNoayA9IHBvbHltb2RTdGVwKGNoaykgXiAodiAmIDB4MWYpO1xuICAgIH1cbiAgICByZXR1cm4gY2hrO1xufVxuZnVuY3Rpb24gY29udmVydChkYXRhLCBpbkJpdHMsIG91dEJpdHMsIHBhZCkge1xuICAgIGxldCB2YWx1ZSA9IDA7XG4gICAgbGV0IGJpdHMgPSAwO1xuICAgIGNvbnN0IG1heFYgPSAoMSA8PCBvdXRCaXRzKSAtIDE7XG4gICAgY29uc3QgcmVzdWx0ID0gW107XG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCBkYXRhLmxlbmd0aDsgKytpKSB7XG4gICAgICAgIHZhbHVlID0gKHZhbHVlIDw8IGluQml0cykgfCBkYXRhW2ldO1xuICAgICAgICBiaXRzICs9IGluQml0cztcbiAgICAgICAgd2hpbGUgKGJpdHMgPj0gb3V0Qml0cykge1xuICAgICAgICAgICAgYml0cyAtPSBvdXRCaXRzO1xuICAgICAgICAgICAgcmVzdWx0LnB1c2goKHZhbHVlID4+IGJpdHMpICYgbWF4Vik7XG4gICAgICAgIH1cbiAgICB9XG4gICAgaWYgKHBhZCkge1xuICAgICAgICBpZiAoYml0cyA+IDApIHtcbiAgICAgICAgICAgIHJlc3VsdC5wdXNoKCh2YWx1ZSA8PCAob3V0Qml0cyAtIGJpdHMpKSAmIG1heFYpO1xuICAgICAgICB9XG4gICAgfVxuICAgIGVsc2Uge1xuICAgICAgICBpZiAoYml0cyA+PSBpbkJpdHMpXG4gICAgICAgICAgICByZXR1cm4gJ0V4Y2VzcyBwYWRkaW5nJztcbiAgICAgICAgaWYgKCh2YWx1ZSA8PCAob3V0Qml0cyAtIGJpdHMpKSAmIG1heFYpXG4gICAgICAgICAgICByZXR1cm4gJ05vbi16ZXJvIHBhZGRpbmcnO1xuICAgIH1cbiAgICByZXR1cm4gcmVzdWx0O1xufVxuZnVuY3Rpb24gdG9Xb3JkcyhieXRlcykge1xuICAgIHJldHVybiBjb252ZXJ0KGJ5dGVzLCA4LCA1LCB0cnVlKTtcbn1cbmZ1bmN0aW9uIGZyb21Xb3Jkc1Vuc2FmZSh3b3Jkcykge1xuICAgIGNvbnN0IHJlcyA9IGNvbnZlcnQod29yZHMsIDUsIDgsIGZhbHNlKTtcbiAgICBpZiAoQXJyYXkuaXNBcnJheShyZXMpKVxuICAgICAgICByZXR1cm4gcmVzO1xufVxuZnVuY3Rpb24gZnJvbVdvcmRzKHdvcmRzKSB7XG4gICAgY29uc3QgcmVzID0gY29udmVydCh3b3JkcywgNSwgOCwgZmFsc2UpO1xuICAgIGlmIChBcnJheS5pc0FycmF5KHJlcykpXG4gICAgICAgIHJldHVybiByZXM7XG4gICAgdGhyb3cgbmV3IEVycm9yKHJlcyk7XG59XG5mdW5jdGlvbiBnZXRMaWJyYXJ5RnJvbUVuY29kaW5nKGVuY29kaW5nKSB7XG4gICAgbGV0IEVOQ09ESU5HX0NPTlNUO1xuICAgIGlmIChlbmNvZGluZyA9PT0gJ2JlY2gzMicpIHtcbiAgICAgICAgRU5DT0RJTkdfQ09OU1QgPSAxO1xuICAgIH1cbiAgICBlbHNlIHtcbiAgICAgICAgRU5DT0RJTkdfQ09OU1QgPSAweDJiYzgzMGEzO1xuICAgIH1cbiAgICBmdW5jdGlvbiBlbmNvZGUocHJlZml4LCB3b3JkcywgTElNSVQpIHtcbiAgICAgICAgTElNSVQgPSBMSU1JVCB8fCA5MDtcbiAgICAgICAgaWYgKHByZWZpeC5sZW5ndGggKyA3ICsgd29yZHMubGVuZ3RoID4gTElNSVQpXG4gICAgICAgICAgICB0aHJvdyBuZXcgVHlwZUVycm9yKCdFeGNlZWRzIGxlbmd0aCBsaW1pdCcpO1xuICAgICAgICBwcmVmaXggPSBwcmVmaXgudG9Mb3dlckNhc2UoKTtcbiAgICAgICAgLy8gZGV0ZXJtaW5lIGNoayBtb2RcbiAgICAgICAgbGV0IGNoayA9IHByZWZpeENoayhwcmVmaXgpO1xuICAgICAgICBpZiAodHlwZW9mIGNoayA9PT0gJ3N0cmluZycpXG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoY2hrKTtcbiAgICAgICAgbGV0IHJlc3VsdCA9IHByZWZpeCArICcxJztcbiAgICAgICAgZm9yIChsZXQgaSA9IDA7IGkgPCB3b3Jkcy5sZW5ndGg7ICsraSkge1xuICAgICAgICAgICAgY29uc3QgeCA9IHdvcmRzW2ldO1xuICAgICAgICAgICAgaWYgKHggPj4gNSAhPT0gMClcbiAgICAgICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoJ05vbiA1LWJpdCB3b3JkJyk7XG4gICAgICAgICAgICBjaGsgPSBwb2x5bW9kU3RlcChjaGspIF4geDtcbiAgICAgICAgICAgIHJlc3VsdCArPSBBTFBIQUJFVC5jaGFyQXQoeCk7XG4gICAgICAgIH1cbiAgICAgICAgZm9yIChsZXQgaSA9IDA7IGkgPCA2OyArK2kpIHtcbiAgICAgICAgICAgIGNoayA9IHBvbHltb2RTdGVwKGNoayk7XG4gICAgICAgIH1cbiAgICAgICAgY2hrIF49IEVOQ09ESU5HX0NPTlNUO1xuICAgICAgICBmb3IgKGxldCBpID0gMDsgaSA8IDY7ICsraSkge1xuICAgICAgICAgICAgY29uc3QgdiA9IChjaGsgPj4gKCg1IC0gaSkgKiA1KSkgJiAweDFmO1xuICAgICAgICAgICAgcmVzdWx0ICs9IEFMUEhBQkVULmNoYXJBdCh2KTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gcmVzdWx0O1xuICAgIH1cbiAgICBmdW5jdGlvbiBfX2RlY29kZShzdHIsIExJTUlUKSB7XG4gICAgICAgIExJTUlUID0gTElNSVQgfHwgOTA7XG4gICAgICAgIGlmIChzdHIubGVuZ3RoIDwgOClcbiAgICAgICAgICAgIHJldHVybiBzdHIgKyAnIHRvbyBzaG9ydCc7XG4gICAgICAgIGlmIChzdHIubGVuZ3RoID4gTElNSVQpXG4gICAgICAgICAgICByZXR1cm4gJ0V4Y2VlZHMgbGVuZ3RoIGxpbWl0JztcbiAgICAgICAgLy8gZG9uJ3QgYWxsb3cgbWl4ZWQgY2FzZVxuICAgICAgICBjb25zdCBsb3dlcmVkID0gc3RyLnRvTG93ZXJDYXNlKCk7XG4gICAgICAgIGNvbnN0IHVwcGVyZWQgPSBzdHIudG9VcHBlckNhc2UoKTtcbiAgICAgICAgaWYgKHN0ciAhPT0gbG93ZXJlZCAmJiBzdHIgIT09IHVwcGVyZWQpXG4gICAgICAgICAgICByZXR1cm4gJ01peGVkLWNhc2Ugc3RyaW5nICcgKyBzdHI7XG4gICAgICAgIHN0ciA9IGxvd2VyZWQ7XG4gICAgICAgIGNvbnN0IHNwbGl0ID0gc3RyLmxhc3RJbmRleE9mKCcxJyk7XG4gICAgICAgIGlmIChzcGxpdCA9PT0gLTEpXG4gICAgICAgICAgICByZXR1cm4gJ05vIHNlcGFyYXRvciBjaGFyYWN0ZXIgZm9yICcgKyBzdHI7XG4gICAgICAgIGlmIChzcGxpdCA9PT0gMClcbiAgICAgICAgICAgIHJldHVybiAnTWlzc2luZyBwcmVmaXggZm9yICcgKyBzdHI7XG4gICAgICAgIGNvbnN0IHByZWZpeCA9IHN0ci5zbGljZSgwLCBzcGxpdCk7XG4gICAgICAgIGNvbnN0IHdvcmRDaGFycyA9IHN0ci5zbGljZShzcGxpdCArIDEpO1xuICAgICAgICBpZiAod29yZENoYXJzLmxlbmd0aCA8IDYpXG4gICAgICAgICAgICByZXR1cm4gJ0RhdGEgdG9vIHNob3J0JztcbiAgICAgICAgbGV0IGNoayA9IHByZWZpeENoayhwcmVmaXgpO1xuICAgICAgICBpZiAodHlwZW9mIGNoayA9PT0gJ3N0cmluZycpXG4gICAgICAgICAgICByZXR1cm4gY2hrO1xuICAgICAgICBjb25zdCB3b3JkcyA9IFtdO1xuICAgICAgICBmb3IgKGxldCBpID0gMDsgaSA8IHdvcmRDaGFycy5sZW5ndGg7ICsraSkge1xuICAgICAgICAgICAgY29uc3QgYyA9IHdvcmRDaGFycy5jaGFyQXQoaSk7XG4gICAgICAgICAgICBjb25zdCB2ID0gQUxQSEFCRVRfTUFQW2NdO1xuICAgICAgICAgICAgaWYgKHYgPT09IHVuZGVmaW5lZClcbiAgICAgICAgICAgICAgICByZXR1cm4gJ1Vua25vd24gY2hhcmFjdGVyICcgKyBjO1xuICAgICAgICAgICAgY2hrID0gcG9seW1vZFN0ZXAoY2hrKSBeIHY7XG4gICAgICAgICAgICAvLyBub3QgaW4gdGhlIGNoZWNrc3VtP1xuICAgICAgICAgICAgaWYgKGkgKyA2ID49IHdvcmRDaGFycy5sZW5ndGgpXG4gICAgICAgICAgICAgICAgY29udGludWU7XG4gICAgICAgICAgICB3b3Jkcy5wdXNoKHYpO1xuICAgICAgICB9XG4gICAgICAgIGlmIChjaGsgIT09IEVOQ09ESU5HX0NPTlNUKVxuICAgICAgICAgICAgcmV0dXJuICdJbnZhbGlkIGNoZWNrc3VtIGZvciAnICsgc3RyO1xuICAgICAgICByZXR1cm4geyBwcmVmaXgsIHdvcmRzIH07XG4gICAgfVxuICAgIGZ1bmN0aW9uIGRlY29kZVVuc2FmZShzdHIsIExJTUlUKSB7XG4gICAgICAgIGNvbnN0IHJlcyA9IF9fZGVjb2RlKHN0ciwgTElNSVQpO1xuICAgICAgICBpZiAodHlwZW9mIHJlcyA9PT0gJ29iamVjdCcpXG4gICAgICAgICAgICByZXR1cm4gcmVzO1xuICAgIH1cbiAgICBmdW5jdGlvbiBkZWNvZGUoc3RyLCBMSU1JVCkge1xuICAgICAgICBjb25zdCByZXMgPSBfX2RlY29kZShzdHIsIExJTUlUKTtcbiAgICAgICAgaWYgKHR5cGVvZiByZXMgPT09ICdvYmplY3QnKVxuICAgICAgICAgICAgcmV0dXJuIHJlcztcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKHJlcyk7XG4gICAgfVxuICAgIHJldHVybiB7XG4gICAgICAgIGRlY29kZVVuc2FmZSxcbiAgICAgICAgZGVjb2RlLFxuICAgICAgICBlbmNvZGUsXG4gICAgICAgIHRvV29yZHMsXG4gICAgICAgIGZyb21Xb3Jkc1Vuc2FmZSxcbiAgICAgICAgZnJvbVdvcmRzLFxuICAgIH07XG59XG5leHBvcnRzLmJlY2gzMiA9IGdldExpYnJhcnlGcm9tRW5jb2RpbmcoJ2JlY2gzMicpO1xuZXhwb3J0cy5iZWNoMzJtID0gZ2V0TGlicmFyeUZyb21FbmNvZGluZygnYmVjaDMybScpO1xuIl0sIm5hbWVzIjpbXSwic291cmNlUm9vdCI6IiJ9\n//# sourceURL=webpack-internal:///(ssr)/./node_modules/bech32/dist/index.js\n");

/***/ })

};
;