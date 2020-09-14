Class CONSTANTS {
    static TIME_TO_LAND_WITH_ACCURACY := 350 + 460
    static KEY_STROKE_DELAY := 80
    static TIME_TO_BHOP := 675
    static DelayTime := 665
    static TIME_TILL_MAX_SPEED := 400
    static TIME_TILL_RUN_SOUND := 445
    static TIME_TO_REACH_CROUCH := 250
    static TIME_TO_REACH_CROUCH_SILENT_JUMP := 100
    static TIME_TO_REACH_JUMP_APPEX := 325
    static TIME_TO_REACH_CROUCH_SILENT_JUMP_APPEX := 225
}

timeInMilli() {
    millis := (A_hour*3600 + A_min*60 + A_sec)*1000 + A_msec
    Return millis
}

Now() {
    return timeInMilli()
}

/*
    Classes
        Generic Classses
        1. Key
            1a. Keys
        2. Action
        Game Action Classes
        3. Movement
            3a. Jump Movement
        4. Weapon
            4a. Weapons
            4b. Weapon Action
            4c. Weapon Stats
            4d. Weapon Data
        5. Ability
        Character Classes
        6. Character State
        7. Character Weapon State
        8. Character Weapon Inventory
        9. Character Movement
        10. Character Abilities
        Game Classes
        11. Game Character
        12. Game State
        13. Game

*/

/*
    1. Key  -------------------------------------------------------------------
*/
Class Key {
    __New(kn,tk) {
        this.name := Chr(123) . kn . Chr(125)
        this.keyName := kn 
        this.triggerKey := tk
        this.down := Chr(123) . kn . " down" . Chr(125)
        this.up := Chr(123) . kn . " up" . Chr(125)
    }
}

/*
    1a. Keys  -----------------------------------------------------------------
*/
Class Keys {
    static w := Key.new("w","w")
    static a := Key.new("a","a")
    static d := Key.new("d","d")
    static s := Key.new("s","s")
    static one := Key.new("1", "1")
    static two := Key.new("2","2")
    static three := Key.new("3","3")
    static space := Key.new("Space", "XButton2") 
    static v := Key.new("v","v")
    static q := Key.new("q","q")
    static e := Key.new("e","e")
    static g := Key.new("g","g")
    static p := Key.new("p","p")
    static period := Key.new(".",".")
    static lshift := Key.new("LShift","LShift")
    static rctrl := Key.new("RCtrl","RCtrl")
    ; static ! := Key.new("!","!")
}

/*
    2. Action  ----------------------------------------------------------------
*/
Class Action {
    __New(ByRef kn, _isToggle := False) {
        this.key := kn
        this.lastUsed := Now()
        this.lastRelease := -1
        this.count := 0
        this.history := [0]
        this.isToggle := _isToggle
        this.toggleState := False
        this.isScriptHeldDown := False
        this.isStartOfHold := False
        this.startOfCurrentHold := Now()
    }
    press() {
        Send "{Blind}" . this.key.name
        this.isScriptHeldDown := False
        this.setPressMetaData()
    }
    pressAndHold() {
        this.isStartOfHold := True
        this.isScriptHeldDown := True
        Send "{Blind}" . this.key.down
        this.setPressMetaData()
    }
    jumpWaitTilAppexPress(ByRef character) {
        character.movements.jump.silentJump()
        Sleep CONSTANTS.TIME_TO_REACH_JUMP_APPEX
        this.press()
    }
    runWaitWaitMaxSpeedUse(ByRef character){

    }
    release() {
        if (!(this.isPhysicallyHeldDown()) && this.isScriptHeldDown) {
            Send this.key.up
        }
        this.isScriptHeldDown := False
        this.setLastRelease()
        this.isStartOfHold := False
    }
    setPressMetaData() {
        this.setCurrentHoldMetaData()
        this.incrementCount()
        this.setToggleState()
    }
    setCurrentHoldMetaData() {
        if(!this.isStartOfHold) {
            this.isStartOfHold := True
            this.startOfCurrentHold := Now()
        }
    }
    setToggleState() {
        if(this.isToggle) {
            this.toggleState := !this.toggleState
        }
    }
    setReleaseMetaData() {
        this.setLastRelease()
        this.isStartOfHold := False
    }
    timeSinceStartOfHold() {
        return Now() - this.startOfCurrentHold 
    }
    setLastRelease() {
        this.lastRelease := Now()
    }
    setLastUsed() {
        this.lastUsed := Now()
    }
    incrementCount() {
        this.count += 1
        timeDiff := Now() - this.lastUsed
        this.history.Push(timeDiff)
    }
    isHeldDown() {
        return this.isScriptHeldDown || GetKeyState(this.key.triggerKey, "p")
    }
    isPhysicallyHeldDown() {
        return GetKeyState(this.key.triggerKey, "p")
    }
    timeSinceLastUsed() {
        return this.lastUsed == 0 ? -1 : Now() - this.lastUsed
    }
    resetToggle() {
        this.toggleState := False
    }
}

/*
    3. Movement  --------------------------------------------------------------
*/
Class Movement {
    __New(ByRef kn, _isToggle := False) {
        this.action := Action.new(kn, _isToggle)
    }
    DirectionalDash(ByRef character) {
        If (this.action.isPhysicallyHeldDown()) {
            character.abilities.signature.useRaw()
        } 
        Else {
            this.action.pressAndHold()
            Sleep 1
            character.abilities.signature.useRaw()
            this.action.release()
        } 
    }
    Dodge(ByRef character) {
        If (character.state.isJett && character.abilities.signature.hasChargesLeft()) {
            this.DirectionalDash(character)
        } else {
            this.KnifeStrafeDodge(character)
        }
    }
    StrafeDodge(ByRef character) {
        If (!this.action.isPhysicallyHeldDown()) {
            this.action.pressAndHold()
        } 
        Sleep 450
        character.movements.jump.silentJump()
        Send "{2} {1}"
        Sleep 175
        this.action.release()
    }
    KnifeStrafeDodge(ByRef character) {
        Send "{3}"
        this.StrafeDodge(character)
    }
    ShootStrafeDodge(ByRef character) {
        Click "Left"
        this.KnifeStrafeDodge(character)
    }
}

/*
    3a. JumpMovement  --------------------------------------------------------------
*/
Class JumpMovement {
    __New(_lshift) {
        this.key := Keys.space
        this.movement := Movement.new(this.key)
        this.lshift := _lshift
    }

    oneJump() {
        this.movement.action.press()
    }
    silentJump() {
        isHeldDown := this.lshift.isPhysicallyHeldDown()
        if(!isHeldDown)
            this.lshift.pressAndHold()
        this.oneJump()
        Sleep 1
        this.lshift.release()
    }
    silentJumpAndHold() {
        isHeldDown := this.lshift.isPhysicallyHeldDown()
        if(!isHeldDown)
            this.lshift.pressAndHold()
        this.jumpAndHold()
        Sleep 1
        this.lshift.release()
    }
    silentJumpWaitTilAppex() {
        this.silentJump()
        Sleep CONSTANTS.TIME_TO_REACH_JUMP_APPEX
    }
    jumpAndHold() {
        this.movement.action.pressAndHold()
    }
    jumpRelease() {
        this.movement.action.release()
    }
}

/*
    4. Weapon
*/
Class Weapon {
    __New(ByRef kn) {
        this.action := Action.new(kn)
        switch kn.keyName {
        case "1":
            this.weaponType := "primary"
    case "2":
        this.weaponType := "sidearm"
case "3":
    this.weaponType := "knife"
default: 
    this.weaponType := "primary"
}
if (False) {
doNothing := "0" "}"
}
}
}

Class WeaponAction {
    __New(ByRef kn, name, _hasContinousShoot := False) {
        this.weapon := Weapon.new(kn)
        this.hasContinousShoot := _hasContinousShoot
    }
    oneShot() {
        Click "Left"
    }
    continousShoot() {
        While GetKeyState("LButton","P") {
            RandMax := 91
            RandDelay := Random(1, RandMax)
            If (GetKeyState("LButton","P")) {
                Click "Left Down"
                Sleep RandDelay
                Click "Left Up"
                Sleep RandMax - RandDelay
            }
        }
    }
}

Class Weapons {
    static classic := WeaponAction.new(Keys.two, "classic", True) 
    static ghost := WeaponAction.new(Keys.two, "ghost", True) 
    static phantom := WeaponAction.new(Keys.one, "phantom", False) 
    static operator := WeaponAction.new(Keys.one, "operator", False) 
    static knife := WeaponAction.new(Keys.three, "knife") 
}

Class WeaponStats {
    __New(_fireRate, _runSpeed, _equipSpeed, _firstShotSpread, _reloadSpeed, _magazineSize, ByRef _damages) {
        this.fireRate := _fireRate
        this.runSpeed := _runSpeed
        this.equipSpeed := _equipSpeed
        this.firstShotSpread := _firstShotSpread
        this.reloadSpeed := _reloadSpeed
        this.magazineSize := _magazineSize
        this.damages := _damages
    }
}

Class WeaponsData {
}

/*
    5. Ability
*/
class Ability {
    __New(ByRef kn, _charges, _maxCharges) {
        this.action := Action.new(kn)
        this.charges := _charges
        this.maxCharges := _maxCharges
    }
    use() {
        if(this.charges > 0) {
            this.decrementCharges()
            this.action.press()
        }
    }
    useRaw() {
        this.decrementCharges()
        this.action.press()
    }
    useAndHoldRaw(){
        this.decrementCharges()
        this.action.pressAndHold()
    }
    release() {
        this.action.release()
    }
    jumpWaitTillAppexUse(ByRef character) {
        this.decrementCharges()
        this.action.jumpWaitTilAppexPress(character)
    }
    decrementCharges() {
        if(this.hasChargesLeft()) {
            this.charges -= 1
        }
    }
    incrementCharges() {
        if(this.hasLessThanMaxCharges()) {
            this.charges += 1
        }
    }
    hasLessThanMaxCharges() {
        return this.charges < this.maxCharges
    }
    hasChargesLeft() {
        return this.charges > 0
    }
    resetToMaxCharges() {
        this.charges := this.maxCharges
    }
}

/*
    6. Character States
*/
Class CharacterState {
    isJett := True
    isJumping := False
    isBHopping := False
    movementDirection := False
    isDead := False
    hasDash := True
    resetCharacterState() {
        this.isJumping := 0
        this.isBHopping := False
        this.isDead := False
        this.hasDash := True
        this.movementDirection := False
    }
}

/*
    7. Character Weapon Inventory
*/
Class CharacterWeaponInventory {
    __New() {
        this.primary := Weapons.phantom
        this.sidearm := Weapons.classic
        this.knife := Weapons.knife
    }
}

/*
    8. Character Weapon State
*/
Class CharacterWeaponState {
    __New(ByRef _movements) {
        this.weaponInventory := CharacterWeaponInventory.new()
        this.currentPrimary := this.weaponInventory.primary
        this.currentSidearm := this.weaponInventory.sidearm
        this.currentWeapon := this.weaponInventory.sidearm
        this.knife := this.weaponInventory.knife
        this.isContinousShoot := False
        this.movements := _movements
    }
    activateContinousShoot() {
        this.isContinousShoot := True
    }
    deactivateContinousShoot() {
        this.isContinousShoot := False
    }
    toggleContinousShoot(){
        this.isContinousShoot := !this.isContinousShoot
    }
    inspectWeaponIfContinous() {
        if(this.isContinousShoot) {
            this.movements.inspectWeapon.press()
        }
    }
    setCurrentWeaponAsSideArm() {
        this.activateContinousShoot()
        this.currentWeapon := this.currentSidearm
    }
    setCurrentWeaponAsPrimary() {
        this.deactivateContinousShoot()
        this.currentWeapon := this.currentPrimary
    }
    setCurrentWeaponAsKnife() {
        this.deactivateContinousShoot()
        this.currentWeapon := this.knife
    }
    isCurrentWeaponPrimary() {
        return this.currentWeapon == this.currentPrimary
    }
    isCurrentWeaponSidearm() {
        return this.currentWeapon == this.currentSidearm
    }
    isCurrentWeaponKnife() {
        return this.currentWeapon == this.knife
    }
    decrementCurrentWeapon() {
        if(this.isCurrentWeaponPrimary()) {
            this.setCurrentWeaponAsSideArm()
        } else if (this.isCurrentWeaponSidearm()) {
            this.setCurrentWeaponAsKnife()
        } else {
            this.setCurrentWeaponAsKnife()
        }
    }
    incrementCurrentWeapon() {
        if(this.isCurrentWeaponKnife()) {
            this.setCurrentWeaponAsSideArm()
        } else if (this.isCurrentWeaponSidearm()) {
            this.setCurrentWeaponAsPrimary()
        } else {
            this.setCurrentWeaponAsPrimary()
        }
    }
}

/*
    9. Character Movement
*/
Class CharacterMovement {
    forwardMove := Movement.new(Keys.w)
    backwardMove := Movement.new(Keys.s)
    leftMove := Movement.new(Keys.a)
    rightMove := Movement.new(Keys.d)
    lcrouch := Action.new(Keys.rctrl, True)
    lshift := Action.new(Keys.lshift, True)
    period := Action.new(Keys.period, True)
    jump := JumpMovement.new(this.lshift)
    inspectWeapon := Action.new(Keys.p)
    __New(ByRef _characterState) {
        this.characterState := _characterState
    }
    moveUntilFullSpeed(ByRef direction, _time := 400) {
        direction.action.pressAndHold()
        this.characterState.movementDirection := direction
        Sleep _time
    }
    moveUntilMaxSound(ByRef direction) {
        direction.action.pressAndHold()
        this.characterState.movementDirection := direction
        Sleep (CONSTANTS.TIME_TILL_RUN_SOUND - 10)
    }
    releaseBHopMovement() {
        if(this.characterState.movementDirection) {
            this.characterState.movementDirection.action.release()
        } 
        this.characterState.movementDirection := False
    }
    isAtFullSpeed(ByRef direction) {
        elapse := direction.action.timeSinceStartOfHold()
        return (this.isAnyMovementKeyHeldDown() && direction.action.isHeldDown() && elapse > CONSTANTS.TIME_TILL_RUN_SOUND)
    }
    continousBHopping() {
        isMoving := this.isAnyMovementKeyHeldDown()
        direction := this.getDirectionToRun()
        instances := 0
        ; if (!this.isAtFullSpeed(direction)) {
        ;     elapse := direction.action.timeSinceStartOfHold()
        ;     moveTime := elapse < CONSTANTS.TIME_TILL_RUN_SOUND ? CONSTANTS.TIME_TILL_RUN_SOUND - elapse : CONSTANTS.TIME_TILL_RUN_SOUND
        ;     this.moveUntilFullSpeed(direction, moveTime)
        ; }

        ; moveTime := !isMoving ? CONSTANTS.TIME_TILL_RUN_SOUND : 200
        this.moveUntilFullSpeed(direction, CONSTANTS.TIME_TILL_RUN_SOUND)
        While (this.jump.movement.action.isHeldDown()) {
            ; Send "{LShift} down"
            this.jump.silentJump()
            ; Send "{LShift} up"
            instances += 1
            Sleep 10
        }
        this.releaseBHopMovement()
    }
    isAnyMovementKeyHeldDown() {
        return this.forwardMove.action.isHeldDown() || this.leftMove.action.isHeldDown() || this.backwardMove.action.isHeldDown() || this.rightMove.action.isHeldDown() 
    }
    getDirectionToRun() {
        isMoving := this.isAnyMovementKeyHeldDown()
        direction := isMoving ? this.getHeldMovemenetKey() : this.forwardMove
        return direction
    }
    getHeldMovemenetKey() {
        if(this.forwardMove.action.isPhysicallyHeldDown()) 
            return this.forwardMove
        else if (this.leftMove.action.isPhysicallyHeldDown()) 
            return this.leftMove
        else if (this.rightMove.action.isPhysicallyHeldDown()) 
            return this.rightMove
        else if (this.backwardMove.action.isPhysicallyHeldDown()) 
            return this.backwardMove
    }
    characterJump() {
        this.jump.oneJump()
    }
    togglelcrouch() {
        this.lcrouch.press()
    }
    silentlCrouchJump() {
        If (!this.lcrouch.toggleState) {
            this.lcrouch.press()
            Sleep CONSTANTS.TIME_TO_REACH_CROUCH_SILENT_JUMP
        }
        this.jump.silentJump()
        Sleep 1
        this.lcrouch.press()
    }
    silentMaxRunHold() {
        this.forwardMove.action.pressAndHold()
        Sleep CONSTANTS.TIME_TILL_RUN_SOUND
    }
    silentMaxRunRelease() {
        this.forwardMove.action.release()
    }
    silentMaxRunShiftlcrouchJump() {
        this.silentMaxRunHold()
        this.jump.silentJump()
        this.silentMaxRunRelease()
    }
    maxSilentRun() {
        direction := this.getDirectionToRun()
        this.moveUntilMaxSound(direction)
        this.lshift.pressAndHold()
        this.period.press()
        Sleep 500
        this.period.press()
        ; this.period.press()
        Sleep 1000
        this.lshift.release()
        direction.action.release()
    }
}

/*
    10. Character Abilities
*/
class CharacterAbilities {
    first := Ability.new(Keys.v, 3, 3)
    second := Ability.new(Keys.q, 2,2)
    signature := Ability.new(Keys.e, 1,1)
    ultimate := Ability.new(Keys.g, 1,1)
}

/*
    11. Game Character
*/
class GameCharacter {
    __New() {
        this.state := CharacterState.new()
        this.movements := CharacterMovement.new(this.state)
        this.weapons := CharacterWeaponState.new(this.movements)
        this.abilities := CharacterAbilities.new()
        this.dashTimer := ObjBindMethod(this, "dash")
        this.updraftTimer := ObjBindMethod(this, "updraft")
    }
    resetCharacterState() {
        this.movements.lcrouch.resetToggle()
        this.abilities.signature.resetToMaxCharges()
    }

    smokeDelayDashFullJump() {
        If (this.state.isJett) {
            this.abilities.first.useRaw()
            SetTimer(this.dashTimer, -200)
            SetTimer(this.updraftTimer, -400)

        }
    }
    dash() {
        this.abilities.signature.useRaw()
    }
    updraft() {
        this.abilities.second.useRaw()
    }
    updraftDash() {
        If (this.state.isJett) {
            this.abilities.second.useRaw()
            Sleep 1
            this.abilities.signature.useRaw()
        }
    }
    silentJumpUseAbility(ByRef _ability) {
        this.movements.jump.silentJump()
        _ability.useRaw()
    }
    silentJumpWaitTillAppexUseAbility(ByRef _ability) {
        this.movements.jump.silentJumpWaitTilAppex()
        _ability.useRaw()
    }
    silentCrouchJumpWaitTillAppexUseAbility(ByRef _ability) {
        this.movements.silentlCrouchJump()
        Sleep CONSTANTS.TIME_TO_REACH_CROUCH_SILENT_JUMP_APPEX
        _ability.useRaw()
    }
}

/*
    12. Game States
*/

Class GameState {
    isInRound := True
    isInGame := True
    __New(ByRef _character) {
        this.character := _character
    }
    toggleInRound() {
        this.isInRound := !this.isInRound
    }
    startRound() {
        isInRound := True
        this.cha
    }
}

/*
    13. Game
*/
Class Game {
    character := GameCharacter.new()
    state := GameState.new(this.character)
}

global g := Game.new()

global hotKeysActive := True
toggleHotKeysState() {
    hotKeysActive := !hotKeysActive
}

/*
    Test Utilities
*/
global testNum := 20
global originalTestNum := testNum
global testNumIncrementRate := 1

noOp() {
    no := False
    MsgBox(getIterations())
}
incrementTestNum() {
    testNum += testNumIncrementRate
}
testSleep() {
    Sleep testNum
    incrementTestNum()
    if(isXIterations(10)) {
        noOp()
    }
    if(isXIterations(20)) {
        noOp()
    }
    if(isXIterations(30)) {
        noOp()
    }
    if(isXIterations(40)) {
        noOp()
    }
    if(isXIterations(50)) {
        noOp()
    }
    if(isXIterations(60)) {
        noOp()
    }
    if(isXIterations(70)) {
        noOp()
    }
    if(isXIterations(80)) {
        noOp()
    }
    if(isXIterations(90)) {
        noOp()
    }
    if(isXIterations(100)) {
        noOp()
    }
}
isXIterations(_iterations) {
return testNum == calcTestNumIterations(_iterations)
}
calcTestNumIterations(_iterations) {
    return originalTestNum + testNumIncrementRate * _iterations
}
getIterations() {
    return (testNum - originalTestNum) / testNumIncrementRate
}
ShiftRun() {
    g.character.movements.forwardMove.action.pressAndHold()
    ; Sleep (CONSTANTS.TIME_TILL_RUN_SOUND - 0)
    Sleep 420
    Loop(5) {
        g.character.movements.lshift.pressAndHold()
        Sleep 500
        g.character.movements.lshift.release()
        Sleep 20
    }
    g.character.movements.forwardMove.action.release()
    incrementTestNum()
    ; }
}
/*
    Test Functions
*/
; RunSoundTest() {
;     g.character.movements.forwardMove.action.pressAndHold()
;     Sleep testNum
;     incrementTestNum()
;     g.character.movements.forwardMove.action.release()
; }
CrouchTest() {
    Click "Right"
    Sleep 50
    Click "Right"
    Sleep 100
    g.character.movements.lcrouch.press()
    testSleep()
    g.character.weapons.currentWeapon.oneShot()
    Sleep 100
    g.character.movements.lcrouch.press()
    Sleep 1450
    Click "Right"
    Sleep 50
    Click "Right"
    Sleep 100
}
/*
    Hotkeys
        1. Weapons
        2. Shooting
        3. Abilities
        4. Movement
            4a. Directional
            4b. Jump
            4c. lcrouch
            4d. Walk
*/

#HotIf (WinActive("VALORANT") && hotKeysActive)
SetKeyDelay(-1)
/*
    1. Weapons ----------------------------------------------------------------
*/
~1:: {
    g.character.weapons.setCurrentWeaponAsPrimary()
    g.character.weapons.deactivateContinousShoot()
    g.character.weapons.inspectWeaponIfContinous()
}
>+1::{
    g.character.weapons.toggleContinousShoot()
    g.character.weapons.inspectWeaponIfContinous()
}
~2:: {
    g.character.weapons.activateContinousShoot()
    g.character.weapons.setCurrentWeaponAsSideArm()
    g.character.weapons.inspectWeaponIfContinous()
}
>+2:: {
    g.character.weapons.toggleContinousShoot()
    g.character.weapons.inspectWeaponIfContinous()
}
~WheelUp::{
    g.character.weapons.setCurrentWeaponAsKnife()
}
~WheelDown:: {
    g.character.weapons.incrementCurrentWeapon()
}

/*
    2. Shooting ---------------------------------------------------------------
*/
~LButton:: {
    if(g.character.weapons.isContinousShoot) {
        g.character.weapons.currentWeapon.continousShoot()
    }
}

/*
    3. Abilities --------------------------------------------------------------
*/
; 
5:: {
    g.character.silentCrouchJumpWaitTillAppexUseAbility(g.character.abilities.first)
}
6:: {
    g.character.silentJumpWaitTillAppexUseAbility(g.character.abilities.first)
}
; <+v::{
;     g.character.silentJumpWaitTillAppexUseAbility(g.character.abilities.first)
; }
; v::{
;     g.character.abilities.first.useRaw()
; }
; !v::{
;     g.character.abilities.first.incrementCharges()
; }
; +q::
; q::{
;     g.character.abilities.second.useRaw()
; }
; !q::{
;     ; g.character.abilities.second.incrementCharges()
; }
; +g::
;     g::{
;         g.character.abilities.ultimate.useRaw()
;     }
;     !g::{
;         g.character.abilities.ultimate.incrementCharges()
;     }
+e:: {
    g.character.abilities.signature.useRaw()
}
e:: {
    g.character.abilities.signature.useRaw()
}
!e:: {
    g.character.abilities.signature.incrementCharges()
}

/*
    4. Movement ---------------------------------------------------------------
        4a. Directional -------------------------------------------------------
*/
~w:: {
    g.character.movements.forwardMove.action.setPressMetaData()
}
~w up:: {
    g.character.movements.forwardMove.action.setReleaseMetaData()
}

~a:: {
    g.character.movements.leftMove.action.setPressMetaData()
}
~a up:: {
    g.character.movements.leftMove.action.setReleaseMetaData()
}
~s:: {
    g.character.movements.backwardMove.action.setPressMetaData()
}
~s up:: {
    g.character.movements.backwardMove.action.setReleaseMetaData()
}
~d:: {
    g.character.movements.rightMove.action.setPressMetaData()
}
~d up:: {
    g.character.movements.rightMove.action.setReleaseMetaData()
}
z:: {
    g.character.movements.leftMove.DirectionalDash(g.character)
}
x:: {
    g.character.movements.backwardMove.DirectionalDash(g.character)
}
c:: {
    g.character.movements.rightMove.DirectionalDash(g.character)
}
+3:: {
    g.character.movements.leftMove.KnifeStrafeDodge(g.character)
}
3:: {
    g.character.movements.rightMove.KnifeStrafeDodge(g.character)
}
t:: {
    g.character.smokeDelayDashFullJump()
}
+t:: {
    g.character.updraftDash()
}
y:: {
    g.character.updraftDash()
}
~+9:: {
    g.character.movements.leftMove.ShootStrafeDodge(g.character)
}
~+0:: {
    g.character.movements.rightMove.ShootStrafeDodge(g.character)
}
/*
    4. Movement ---------------------------------------------------------------
        4a. Jump --------------------------------------------------------------
*/
XButton2:: {
    g.character.movements.continousBHopping()
}

XButton2 up:: {
    g.character.movements.releaseBHopMovement()
}
+space:: {
    g.character.movements.jump.silentJumpAndHold()
}
space:: {
    g.character.movements.jump.silentJumpAndHold()
}
+space up:: {
    g.character.movements.jump.jumpRelease()
}
space up:: {
    g.character.movements.jump.jumpRelease()
}
/*
    4. Movement ---------------------------------------------------------------
        4a. Croch -------------------------------------------------------------
*/
~RCtrl:: {
    g.character.movements.lcrouch.setPressMetaData()
}

+7:: {
    g.character.movements.silentlCrouchJump()
}
Numpad7::{
    g.character.movements.maxSilentRun()
}
/*
    Tests
*/
; Numpad1::{
;     Send "{Space}"
;     g.character.abilities.second.useRaw()
; }
; Numpad2::{
;     g.character.silentJumpUseAbility(g.character.abilities.second)
; }
#HotIf

End:: {
    toggleHotKeysState()
}
