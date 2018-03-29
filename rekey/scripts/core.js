let __rekey_intrinsics__ = {
    remapRules: []
};

class RemapRule {
    constructor(predict, remapped) {
        this.predict = predict;
        this.remapped = remapped;
    }
}

/**
 *
 * @param predict
 * @param remapped {function(Context)}
 */
function addRemap(predict, remapped) {
    __rekey_intrinsics__.remapRules.push(
        new RemapRule(predict, remapped)
    );
}

function getKeyName(keyCode) {
    const name = KeyCodeToKeyName[keyCode];
    if (!name) {
        console.log(`Unknown KeyCode: 0x${keyCode.toString(16)}`)
    }
    return name
}

function getKeyCode(keyName) {
    const code = KeyCodes[keyName];
    if (code === undefined) {
        console.log(`Unknown KeyName: ${keyName}`);
    }
    return code;
}

/*

example of remapping A => B:

  addRemap(e=>e.keyCode==getKeyCode('A'), e=>{
    e.keyCode=getKeyCode('B')
    Key.emit(e)
  }

  addRemap('A','B')

example of remapping Alt + A => B:

  addRemap(e=>e.isAlt && e.keyCode==getKeyCode('A'), e=>{
    e.keyCode=getKeyCode('B')
    Key.emit(e)
  }

  addRemap('A-A','B')

example of remapping Alt + A => B :

  addRemap(e=>e.isAlt && e.keyCode==getKeyCode('A'), e=>{
    e.keyCode=getKeyCode('B')
    Key.emit(e)
  }

  addRemap('A-A','B')
*/

function executeRemapAction(ctx, remapped) {
    if (remapped instanceof InOut) {
        remapped.output(ctx);
        return
    }
    switch (typeof (remapped)) {
        case 'function':
            remapped(ctx);
    }
}

const Masks = {
    LCONTROL: 1<<0,
    LSHIFT: 1<<1,
    RSHIFT: 1<<2,
    LCOMMAND: 1<<3,
    RCOMMAND: 1<<4,
    LALT: 1<<5
};

class Context {

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

    get isLeftControlPressed(){
        return (this.flags & Masks.LCONTROL) !== 0;
    }

}


/**
 * @param ctx {Context}
 * @param remapRules {[RemapRule]}
 * @returns {boolean}
 */
function acquireRemapAction(ctx, remapRules) {
    for (let remapRule of remapRules) {
        let predictVal = remapRule.predict;
        let remapped = remapRule.remapped;

        if (predictVal instanceof InOut) {
            if (match(ctx, predictVal)) {
                executeRemapAction(ctx, remapped);
                return true;
            }
            continue;
        }

        // remapRules.forEach((predict, remapped) => {
        switch (typeof (predictVal)) {
            case 'number':
                if (predictVal === ctx.keyCode) {
                    executeRemapAction(ctx,remapped);
                    return true
                }
                break;
            case 'string':
                if (predictVal.toLowerCase() === getKeyName(ctx.keyCode).toLowerCase()) {
                    executeRemapAction(ctx,remapped);
                    return true
                }
                break;
            case 'function':
                if (predictVal(ctx)) {
                    executeRemapAction(ctx,remapped);
                    return true
                }
                break;
            default:
                if (Array.isArray(predictVal)) {
                    for (let pred of predictVal) {
                        if (acquireRemapAction(ctx, {
                            predict: pred,
                            remapped: remapped
                        })) {
                            return true
                        }
                    }
                    return true
                }
        }
    }
}

// noinspection JSUnusedGlobalSymbols
function onKey(keyCode, flags, isRepeat, isUp, isSysKey, keyboardType) {
    let ctx = new Context(keyCode, flags, isRepeat, isUp, isSysKey, keyboardType);
    if (!acquireRemapAction(
        ctx,
        __rekey_intrinsics__.remapRules)) {
        Key.emit(keyCode, {
            isUp: isUp,
            keyboardType: keyboardType
        });
    }
}


const KeyCodes = {
    Enter: 0x24,
    tab: 0x30,
    space: 0x31,
    delete: 0x33,
    escape: 0x35,
    command: 0x37,
    shift: 0x38,
    capsLock: 0x39,
    option: 0x3A,
    control: 0x3B,
    rightShift: 0x3C,
    rightOption: 0x3D,
    rightControl: 0x3E,
    leftArrow: 0x7B,
    rightArrow: 0x7C,
    downArrow: 0x7D,
    upArrow: 0x7E,
    volumeUp: 0x48,
    volumeDown: 0x49,
    mute: 0x4A,
    help: 0x72,
    home: 0x73,
    pageUp: 0x74,
    forwardDelete: 0x75,
    end: 0x77,
    pageDown: 0x79,
    function: 0x3F,
    f1: 0x7A,
    f2: 0x78,
    f4: 0x76,
    f5: 0x60,
    f6: 0x61,
    f7: 0x62,
    f3: 0x63,
    f8: 0x64,
    f9: 0x65,
    f10: 0x6D,
    f11: 0x67,
    f12: 0x6F,
    f13: 0x69,
    f14: 0x6B,
    f15: 0x71,
    f16: 0x6A,
    f17: 0x40,
    f18: 0x4F,
    f19: 0x50,
    f20: 0x5A,

    // US-ANSI Keyboard Positions,
    // eg. These key codes are for the physical key (in any keyboard layout),
    // at the location of the named key in the US-ANSI layout.,
    a: 0x00,
    b: 0x0B,
    c: 0x08,
    d: 0x02,
    e: 0x0E,
    f: 0x03,
    g: 0x05,
    h: 0x04,
    i: 0x22,
    j: 0x26,
    k: 0x28,
    l: 0x25,
    m: 0x2E,
    n: 0x2D,
    o: 0x1F,
    p: 0x23,
    q: 0x0C,
    r: 0x0F,
    s: 0x01,
    t: 0x11,
    u: 0x20,
    v: 0x09,
    w: 0x0D,
    x: 0x07,
    y: 0x10,
    z: 0x06,

    zero: 0x1D,
    one: 0x12,
    two: 0x13,
    three: 0x14,
    four: 0x15,
    five: 0x17,
    six: 0x16,
    seven: 0x1A,
    eight: 0x1C,
    nine: 0x19,

    equals: 0x18,
    minus: 0x1B,
    semicolon: 0x29,
    apostrophe: 0x27,
    comma: 0x2B,
    period: 0x2F,
    forwardSlash: 0x2C,
    backslash: 0x2A,
    grave: 0x32,
    leftBracket: 0x21,
    rightBracket: 0x1E,

    keypadDecimal: 0x41,
    keypadMultiply: 0x43,
    keypadPlus: 0x45,
    keypadClear: 0x47,
    keypadDivide: 0x4B,
    keypadEnter: 0x4C,
    keypadMinus: 0x4E,
    keypadEquals: 0x51,
    keypad0: 0x52,
    keypad1: 0x53,
    keypad2: 0x54,
    keypad3: 0x55,
    keypad4: 0x56,
    keypad5: 0x57,
    keypad6: 0x58,
    keypad7: 0x59,
    keypad8: 0x5B,
    keypad9: 0x5C
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
     * @param next {InOut|string}
     * @param predict {function(Context)}
     * @param output {function(Context)}
     */
    constructor(next, predict, output) {
        this.next = next;
        this.predict = predict;
        this.output = output;
    }
}

let emitNext = (ctx, nextValue) => {
    if (nextValue instanceof InOut) {
        nextValue.output(ctx);
        return;
    }
    switch (typeof(nextValue)) {
        case "string":
            Key.emit(getKeyCode(nextValue));
            break;
        case "number":
            Key.emit(nextValue);
            break;
        default:
            console.log(typeof(nextValue))
    }
}

let Control = next => {
    const inout = new InOut(
        next,
        ctx => ctx.isLeftControlPressed,
        ctx => {
            if (!ctx.isLeftControlPressed) {
                Key.emitFlagsChange({flags: ctx.flags | Masks.LCONTROL, keyboardType: ctx.keyboardType});
            }
            emitNext(ctx, next);
        });
    return inout;
};

// addRemap(Control(KeyCodes.e), Control(KeyCodes.a));

Mouse.setAttenuation(11);
addRemap(Control(KeyCodes.e), ctx => Mouse.setForce({y: ctx.isUp ? 0 : -12}));
addRemap(Control(KeyCodes.d), ctx => Mouse.setForce({y: ctx.isUp ? 0 : 12}));
addRemap(Control(KeyCodes.s), ctx => Mouse.setForce({x: ctx.isUp ? 0 : -12}));
addRemap(Control(KeyCodes.f), ctx => Mouse.setForce({x: ctx.isUp ? 0 : 12}));
addRemap(Control(KeyCodes.g), Control(KeyCodes.a));