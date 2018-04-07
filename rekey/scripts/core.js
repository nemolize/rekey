let __rekey_intrinsics__ = {
    /** @type [RemapRule] */    remapRules: [],
    /** @type Set<RemapRule> */    triggeredRules: new Set(),
    /** @type Set<number> */    pressedKeys: new Set()
};

class RemapRule {
    /**
     * @param predict {InOut|number}
     * @param remapped {InOut|function(Context)|number}
     * @param releaseFunc {(InOut|function(Context))?}
     */
    constructor(predict, remapped, releaseFunc) {
        this.predict = predict;
        this.remapped = remapped;
        this.releaseFunc = releaseFunc;
    }
}

/**
 *
 * @param predict {InOut|number}
 * @param remapped {InOut|function(Context)|number}
 * @param releaseFunc {(InOut|function(Context)|number)?}
 */
function addRemap(predict, remapped, releaseFunc) {
    __rekey_intrinsics__.remapRules.push(
        new RemapRule(predict, remapped, releaseFunc)
    );
}

function getKeyName(keyCode) {
    const name = KeyCodeToKeyName[keyCode];
    if (!name) {
        console.log(`Unknown KeyCode: 0x${keyCode.toString(16)}`)
    }
    return name
}

/** @param ctx {Context}
 *  @param remapped {Function|number} */
function executeRemapAction(ctx, remapped) {
    let newCtx = new Context(ctx.keyCode, 0, ctx.isRepeat, ctx.isUp, ctx.isSysKey, ctx.keyboardType);
    let next = remapped;

    while (next instanceof InOut)
        next = next.output(newCtx);

    if (typeof (next) === 'function')
        next(newCtx);
    else if (typeof (next) === 'number') {
        // small flags fix according to next flags
        {
            newCtx.flags |= 256;
            // noinspection JSBitwiseOperatorUsage
            if (newCtx.flags & Masks.LSHIFT) newCtx.flags |= Masks.SHIFT_MASK;
            // noinspection JSBitwiseOperatorUsage
            if (newCtx.flags & Masks.LCONTROL) newCtx.flags |= Masks.CTRL_MASK;
        }

        // change flags if current flags differs from next
        if (ctx.flags !== newCtx.flags) Key.emitFlagsChange({flags: newCtx.flags});


        Key.emit(next, newCtx);
        // get flags back to before
        if (ctx.flags !== newCtx.flags) Key.emitFlagsChange({flags: ctx.flags});
    } else {
        console.log(`unknown type ${typeof (next)}`);
    }
}

const Masks = {
    CTRL_MASK: 1 << 18,
    LCONTROL: 1 << 0,
    SHIFT_MASK: 1 << 17,
    LSHIFT: 1 << 1,
    RSHIFT: 1 << 2,
    LCOMMAND: 1 << 3,
    RCOMMAND: 1 << 4,
    LALT: 1 << 5
};

class Context {

    /**
     * @param keyCode number
     * @param flags integer
     * @param isRepeat boolean
     * @param isUp boolean
     * @param isSysKey boolean
     * @param keyboardType integer
     */
    constructor(keyCode,
                flags,
                isRepeat,
                isUp,
                isSysKey,
                keyboardType) {
        this.keyCode = keyCode;
        this.flags = flags;
        this.isRepeat = isRepeat;
        this.isUp = isUp;
        this.isSysKey = isSysKey;
        this.keyboardType = keyboardType;
    }

    get isLeftShiftPressed() {
        return (this.flags & Masks.LSHIFT) !== 0;
    }

    get isLeftControlPressed() {
        return (this.flags & Masks.LCONTROL) !== 0;
    }

}

/**
 * @param ctx {Context}
 * @param remapRules {[RemapRule]}
 * @returns RemapRule
 */
function findMatchedRule(ctx, remapRules) {
    for (let remapRule of remapRules) {
        const predictVal = remapRule.predict;
        if (predictVal instanceof InOut) {
            if (match(ctx, predictVal))
                return remapRule;
        } else if (typeof (predictVal) === 'number') {
            if (predictVal === ctx.keyCode)
                return remapRule;
        } else if (typeof (predictVal) === 'string') {
            if (predictVal.toLowerCase() === getKeyName(ctx.keyCode).toLowerCase())
                return remapRule;
        } else if (typeof (predictVal) === 'function') {
            if (predictVal(ctx))
                return remapRule;
        } else if (Array.isArray(predictVal))
            for (let pred of predictVal)
                if (findMatchedRule(ctx, {
                    predict: pred,
                    remapped: remapRule.remapped
                }))
                    return remapRule;
    }
}

/**
 * @param ctx {Context}
 * @param remapRules {[RemapRule]}
 * @returns {RemapRule}
 */
function acquireRemapAction(ctx, remapRules) {
    const matchedRemapRule = findMatchedRule(ctx, remapRules);
    if (matchedRemapRule) {
        __rekey_intrinsics__.triggeredRules.add(matchedRemapRule);
        executeRemapAction(ctx, matchedRemapRule.remapped);
        return matchedRemapRule
    }
}

// noinspection JSUnusedGlobalSymbols
function onFlagsChanged(key, flags, isRepeat, isUp, isSysKey, keyboardType) {
    Key.emitFlagsChange({flags: flags, keyboardType: keyboardType})
}

// noinspection JSUnusedGlobalSymbols
function onKey(keyCode, flags, isRepeat, isUp, isSysKey, keyboardType) {
    let ctx = new Context(keyCode, flags, isRepeat, isUp, isSysKey, keyboardType);
    if (!isUp) {
        __rekey_intrinsics__.pressedKeys.add(keyCode);
        const matchedRemapRule = acquireRemapAction(ctx, __rekey_intrinsics__.remapRules);
        if (!matchedRemapRule) Key.emit(keyCode, {isUp: isUp, keyboardType: keyboardType});
    } else {
        __rekey_intrinsics__.pressedKeys.delete(keyCode);
        const releaseTargets = Array.from(__rekey_intrinsics__.triggeredRules).filter(rule => {
                let next = rule.predict;
                while (next instanceof InOut) {
                    if (!next.predict(ctx)) return true;
                    next = next.next
                }
                if (typeof(next) === 'number') {
                    return !__rekey_intrinsics__.pressedKeys.has(next)
                }
            }
        );

        releaseTargets.forEach(rule => {
            if (rule.releaseFunc) rule.releaseFunc(ctx);
            else {
                executeRemapAction(ctx, rule.remapped);
                __rekey_intrinsics__.triggeredRules.delete(rule);
            }
        });

        if (releaseTargets.length === 0) {
            Key.emit(keyCode, ctx);
        }

    }
}

const KeyCodes = {
    Enter: 36,
    Tab: 48,
    Space: 49,
    Delete: 51,
    Escape: 53,
    Command: 55,
    Shift: 56,
    CapsLock: 57,
    Option: 58,

    Control: 59,
    RightShift: 60,
    RightOption: 61,
    RightControl: 62,

    LeftArrow: 123,
    RightArrow: 124,
    DownArrow: 125,
    UpArrow: 126,

    VolumeUp: 72,
    VolumeDown: 73,
    Mute: 74,
    Help: 114,

    Home: 115,
    PageUp: 116,
    ForwardDelete: 117,
    End: 119,
    PageDown: 121,

    Function: 63,

    F1: 122,
    F2: 120,
    F4: 118,
    F5: 96,
    F6: 97,
    F7: 98,
    F3: 99,
    F8: 100,
    F9: 101,
    F10: 109,
    F11: 103,
    F12: 111,
    F13: 105,
    F14: 107,
    F15: 113,
    F16: 106,
    F17: 64,
    F18: 79,
    F19: 80,
    F20: 90,

    A: 0,
    B: 11,
    C: 8,
    D: 2,
    E: 14,
    F: 3,
    G: 5,
    H: 4,
    I: 34,
    J: 38,
    K: 40,
    L: 37,
    M: 46,
    N: 45,
    O: 31,
    P: 35,
    Q: 12,
    R: 15,
    S: 1,
    T: 17,
    U: 32,
    V: 9,
    W: 13,
    X: 7,
    Y: 16,
    Z: 6,

    _0: 29,
    _1: 18,
    _2: 19,
    _3: 20,
    _4: 21,
    _5: 23,
    _6: 22,
    _7: 26,
    _8: 28,
    _9: 25,

    Equals: 24,
    Minus: 27,
    Semicolon: 41,
    Apostrophe: 39,
    Comma: 43,
    Period: 47,
    ForwardSlash: 44,
    Backslash: 42,
    Grave: 50,
    LeftBracket: 33,
    RightBracket: 30,

    KeypadDecimal: 65,
    KeypadMultiply: 67,
    KeypadPlus: 69,
    KeypadClear: 71,
    KeypadDivide: 75,
    KeypadEnter: 76,
    KeypadMinus: 78,
    KeypadEquals: 81,

    Keypad0: 82,
    Keypad1: 83,
    Keypad2: 84,
    Keypad3: 85,
    Keypad4: 86,
    Keypad5: 87,
    Keypad6: 88,
    Keypad7: 89,
    Keypad8: 91,
    Keypad9: 92
};

const KeyCodeToKeyName = Object.keys(KeyCodes).reduce((acc, key) => {
    acc[KeyCodes[key]] = key;
    return acc;
}, {});

/**
 * @param predict {InOut|string}
 * @param ctx {Context}
 */
function match(ctx, predict) {
    if (predict instanceof InOut) {
        if (!predict.predict(ctx)) {
            return
        }
        return match(ctx, predict.next)
    }

    switch (typeof(predict)) {
        case 'string':
            return predict.toLowerCase() === getKeyName(ctx.keyCode);
        case 'number':
            return predict === ctx.keyCode;
    }
}

class InOut {
    /**
     * @param next {InOut|string|number}
     * @param predict {Function|number|InOut}
     * @param output {(Function|number|InOut)?}
     * @param release {(Function|InOut)?}
     */
    constructor(next, predict, output, release) {
        this.next = next;
        this.predict = predict;
        this.output = ctx => {
            output(ctx);
            return this.next;
        };
        this.release = release;
    }
}

let Control = next => new InOut(next,
    ctx => ctx.isLeftControlPressed,
    ctx => !ctx.isUp ? (ctx.flags |= Masks.LCONTROL) : (ctx.flags &= !Masks.LCONTROL)
);

let Shift = (next) => new InOut(next,
    ctx => ctx.isLeftShiftPressed,
    ctx => ctx.flags |= Masks.LSHIFT
);

let Up = (next) => new InOut(next,
    ctx => ctx.isUp,
    ctx => ctx.isUp = true,
    ctx => ctx.isUp
);

Mouse.setAttenuation(11);

addRemap(Control(KeyCodes.E),
    ctx => Mouse.setForce({y: ctx.isUp ? 0 : -12}),
    ctx => Mouse.setForce({y: 0})
);
// addRemap(Control(KeyCodes.D), ctx => Mouse.setForce({y: ctx.isUp ? 0 : 12}));
// addRemap(Control(KeyCodes.S), ctx => Mouse.setForce({x: ctx.isUp ? 0 : -12}));
// addRemap(Control(KeyCodes.F), ctx => Mouse.setForce({x: ctx.isUp ? 0 : 12}));
addRemap(Control(KeyCodes.G), Shift(KeyCodes.A));
addRemap(Shift(KeyCodes.F), Control(KeyCodes.A));
addRemap(Control(KeyCodes._1), Shift(KeyCodes._2));