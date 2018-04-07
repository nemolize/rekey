class Mouse {
    /** @param [arg.x] number
     *  @param [arg.y] number */
    static setForce(arg);

    /** @param arg number */
    static setAttenuation(arg);
}

class Key {
    /** @param arg.flags number */
    static emitFlagsChange(arg);

    /** @return number */
    static getModifierFlags();

    /**
     * @param keyCode number
     * @param [option] object
     * @param [option.isUp] boolean
     * @param [option.keyboardType] number
     */
    static emit(keyCode, option);
}