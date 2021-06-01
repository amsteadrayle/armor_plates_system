#include "script_component.hpp"

if (is3DEN) exitWith {};

["CAManBase", "Hit", {
    _this call FUNC(hitEh);
}, true, [], true] call CBA_fnc_addClassEventHandler;

["CAManBase", "InitPost", {
    params ["_unit"];

    private _arr = [_unit, "Heal", "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_reviveMedic_ca.paa", "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_reviveMedic_ca.paa",
        // condition show
        format ["alive _target && {(lifeState _target) == 'INCAPACITATED' && {_this getUnitTrait 'Medic' && {(_target distance _this) < 4 && {[_this] call %1 > 0}}}}", QFUNC(hasHealItems)],
        // condition progress
        "alive _target && {(lifeState _target) == 'INCAPACITATED'}", {
        // code start
        params ["_target", "_caller"];
        private _isProne = stance _caller == "PRONE";
        _caller setVariable [QGVAR(wasProne), _isProne];
        private _medicAnim = ["AinvPknlMstpSlayW[wpn]Dnon_medicOther", "AinvPpneMstpSlayW[wpn]Dnon_medicOther"] select _isProne;
        private _wpn = ["non", "rfl", "lnr", "pst"] param [["", primaryWeapon _caller, secondaryWeapon _caller, handgunWeapon _caller] find currentWeapon _caller, "non"];
        _medicAnim = [_medicAnim, "[wpn]", _wpn] call CBA_fnc_replace;
        if (_medicAnim != "") then {
            _caller playMove _medicAnim;
        };
    }, {
        // code progress
    }, {
        // codeCompleted
        params ["_target", "_caller"];
        private _ret = [_caller] call FUNC(hasHealItems);
        if (_ret isEqualTo 1) then {
            _caller removeItem "FirstAidKit";
        };
        [QGVAR(heal), [_target, _caller], _target] call CBA_fnc_targetEvent;
    }, {
        // code interrupted
        params ["", "_caller"];
        private _anim = ["amovpknlmstpsloww[wpn]dnon", "amovppnemstpsrasw[wpn]dnon"] select (_caller getVariable [QGVAR(wasProne), false]);
        private _wpn = ["non", "rfl", "lnr", "pst"] param [["", primaryWeapon _caller, secondaryWeapon _caller, handgunWeapon _caller] find currentWeapon _caller, "non"];
        _anim = [_anim, "[wpn]", _wpn] call CBA_fnc_replace;
        [QGVAR(switchMove), [_caller, _anim]] call CBA_fnc_globalEvent;
    }, [], GVAR(medicReviveTime), 15, false, false, true];

    _arr call BIS_fnc_holdActionAdd;
    private _arr2 = +_arr;
    _arr2 set [4, format ["alive _target && {(lifeState _target) == 'INCAPACITATED' && {!(_this getUnitTrait 'Medic') && {(_target distance _this) < 4 && {[_this] call %1 > 0}}}}", QFUNC(hasHealItems)]];
    _arr2 set [11, GVAR(noneMedicReviveTime)];
    _arr2 call BIS_fnc_holdActionAdd;

    _unit addEventHandler ["HandleDamage", {
        _this call FUNC(handleDamageEh);
    }];
}, true, [], true] call CBA_fnc_addClassEventHandler;

["CAManBase", "HandleHeal", {
    [{
        _this call FUNC(handleHealEh);
    }, _this, 5] call CBA_fnc_waitAndExecute;
    true
}, true, [], true] call CBA_fnc_addClassEventHandler;

["unit", {
    params ["_newUnit", "_oldUnit"];
    [_newUnit] call FUNC(updatePlateUi);
    [_newUnit] call FUNC(updateHPUi);
}] call CBA_fnc_addPlayerEventHandler;

[QGVAR(heal), {
    _this call FUNC(handleHealEh);
}] call CBA_fnc_addEventHandler;

[QGVAR(switchMove), {
    params ["_unit", "_anim"];
    _unit switchMove _anim;
}] call CBA_fnc_addEventHandler;

if !(hasInterface) exitWith {};

GVAR(fullWidth) = 10 * ( ((safezoneW / safezoneH) min 1.2) / 40);
GVAR(fullHeight) = 0.75 * ( ( ((safezoneW / safezoneH) min 1.2) / 1.2) / 25);

{
    ctrlDelete (_x select 0);
    ctrlDelete (_x select 1);
} forEach (uiNamespace getVariable [QGVAR(plateControls), []]);
uiNamespace setVariable [QGVAR(plateControls), []];

{
    ctrlDelete _x;
} forEach (uiNamespace getVariable [QGVAR(plateProgressBar), []]);
ctrlDelete (uiNamespace getVariable [QGVAR(mainControl), controlNull]);
ctrlDelete (uiNamespace getVariable [QGVAR(hpControl), controlNull]);

player addEventHandler ["Respawn", {
    // player setVariable [QGVAR(plates), []];
    player setVariable [QGVAR(hp), GVAR(maxUnitHP)];
    player setVariable [QGVAR(vestContainer), vestContainer player];
    [player] call FUNC(updatePlateUi);
    [player] call FUNC(updateHPUi);
    player setCaptive false;
    [] call FUNC(addPlayerHoldActions);
}];

player addEventHandler ["Killed", {
    params ["_unit"];
    private _oldVestcontainer = _unit getVariable [QGVAR(vestContainer), objNull];
    _oldVestcontainer setVariable [QGVAR(plates), _oldVestcontainer getVariable [QGVAR(plates), []], true];
}];

[] call FUNC(addPlayerHoldActions);

[{
    time > 1
}, {
    [] call FUNC(initPlates);
    player setVariable [QGVAR(vestContainer), vestContainer player];
    ["cba_events_loadoutEvent",{
        params ["_unit", "_oldLoadout"];
        private _currentVestContainer = vestContainer _unit;
        private _oldVestcontainer = _unit getVariable [QGVAR(vestContainer), objNull];

        if ((isNull _currentVestContainer && {!isNull _oldVestcontainer}) ||
            (!isNull _currentVestContainer && {isNull _oldVestcontainer}) ||
            (_currentVestContainer isNotEqualTo _oldVestcontainer)) then {
            _oldVestcontainer setVariable [QGVAR(plates), _oldVestcontainer getVariable [QGVAR(plates), []], true];
            _unit setVariable [QGVAR(vestContainer), _currentVestContainer];
            [_unit] call FUNC(updatePlateUi);
        };
    }] call CBA_fnc_addEventHandler;
}] call CBA_fnc_waitUntilAndExecute;

#include "\a3\ui_f\hpp\defineDIKCodes.inc"
[LLSTRING(category), QGVAR(addPlate), LLSTRING(addPlateKeyBind), {
    private _player = call CBA_fnc_currentUnit;
    if ((stance _player) == "PRONE" || {
        !([_player] call FUNC(canPressKey)) || {
        !([_player] call FUNC(canAddPlate))}}) exitWith {false};

    GVAR(addPlateKeyUp) = false;
    [_player] call FUNC(addPlate);

    true
},
{
    GVAR(addPlateKeyUp) = true;
    false
},
[DIK_T, [false, false, false]], false] call CBA_fnc_addKeybind;

// (vestContainer player) setVariable [QGVAR(plates), [GVAR(maxPlateHealth),GVAR(maxPlateHealth),GVAR(maxPlateHealth)]];
// player setVariable [QGVAR(hp), 20];
