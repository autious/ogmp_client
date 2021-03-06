#include "aschar.as"
#include "situationawareness.as"

float grab_key_time;
bool listening = false;
bool delay_jump;

Situation situation;

int IsUnaware() {
    return 0;
}

void NotifySound(int created_by_id, float max_dist, vec3 pos) {}

enum DropKeyState {_dks_nothing, _dks_pick_up, _dks_drop, _dks_throw};
DropKeyState drop_key_state = _dks_nothing;

enum ItemKeyState {_iks_nothing, _iks_sheathe, _iks_unsheathe};
ItemKeyState item_key_state = _iks_nothing;

void AIMovementObjectDeleted(int id) {
}

string GetIdleOverride(){
    return "";
}

float last_noticed_time;

void UpdateBrain(const Timestep &in ts){
    startled = false;    
    if(GetInputDown(this_mo.controller_id, "grab")){
        grab_key_time += ts.step();
    } else {
        grab_key_time = 0.0f;
    }

    if(time > last_noticed_time + 0.2f){
        array<int> characters;
        GetVisibleCharacters(0, characters);
        for(uint i=0; i<characters.size(); ++i){
            situation.Notice(characters[i]);
        }
        last_noticed_time = time;
    }

    force_look_target_id = situation.GetForceLookTarget();

    if(!GetInputDown(this_mo.controller_id, "drop")){
        drop_key_state = _dks_nothing;
    } else if (drop_key_state == _dks_nothing){
        if((weapon_slots[primary_weapon_slot] == -1 || (weapon_slots[secondary_weapon_slot] == -1 && duck_amount < 0.5f)) &&
            GetNearestPickupableWeapon(this_mo.position, _pick_up_range) != -1)
        {
            drop_key_state = _dks_pick_up;
        } else {
            if(GetInputDown(this_mo.controller_id, "crouch") && 
               duck_amount > 0.5f && 
               on_ground && 
               !flip_info.IsFlipping())
            {
                drop_key_state = _dks_drop;
            } else {
                drop_key_state = _dks_throw;
            }
        }
    } 
    
    if(!GetInputDown(this_mo.controller_id, "item")){
        item_key_state = _iks_nothing;
    } else if (item_key_state == _iks_nothing){
        if(weapon_slots[primary_weapon_slot] == -1 ){
            item_key_state = _iks_unsheathe;
        } else {//if(held_weapon != -1 && sheathed_weapon == -1){
            item_key_state = _iks_sheathe;
        }
    }

    if(delay_jump && !GetInputDown(this_mo.controller_id, "jump")){
        delay_jump = false;
    }
}

vec3 GetTargetJumpVelocity() {
    return vec3(0.0f);    
}

bool TargetedJump() {
    return false;
}

bool IsAware(){
    return true;
}

void ResetMind() {
    situation.clear();
}

int IsIdle() {
    return 0;
}

void HandleAIEvent(AIEvent event){
    if(event == _climbed_up){
        delay_jump = true;
    }
}

void MindReceiveMessage(string msg){
}

bool WantsToCrouch() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "crouch");
}

bool WantsToRoll() {
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "crouch");
}

bool WantsToJump() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "jump") && !delay_jump;
}

bool WantsToAttack() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "attack");
}

bool WantsToRollFromRagdoll(){
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "crouch");
}

bool WantsToFlip() {
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "crouch");
}

bool WantsToGrabLedge() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "grab");
}

bool WantsToThrowEnemy() {
    if(!this_mo.controlled) return false;
    //if(holding_weapon) return false;
    return grab_key_time > 0.2f;
}

bool WantsToDragBody() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "grab");
}

bool WantsToPickUpItem() {
    if(!this_mo.controlled) return false;
    return drop_key_state == _dks_pick_up;
}

bool WantsToDropItem() {
    if(!this_mo.controlled) return false;
    return drop_key_state == _dks_drop;
}

bool WantsToThrowItem() {
    if(!this_mo.controlled) return false;
    return drop_key_state == _dks_throw;
}

bool WantsToSheatheItem() {
    if(!this_mo.controlled) return false;
    return item_key_state == _iks_sheathe;
}

bool WantsToUnSheatheItem(int &out src) {
    if(!this_mo.controlled) return false;
    if(item_key_state != _iks_unsheathe){ 
        return false;
    }
    src = -1;
    if(weapon_slots[_sheathed_right] != -1){
        src = _sheathed_right;
    } else if(weapon_slots[_sheathed_left] != -1){
        src = _sheathed_left;
    }
    return true;
}


bool WantsToStartActiveBlock(const Timestep &in ts){
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "grab");
}

bool WantsToFeint(){
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "grab");
}

bool WantsToCounterThrow(){
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "grab");
}

bool WantsToJumpOffWall() {
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "jump");
}

bool WantsToFlipOffWall() {
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "crouch");
}

bool WantsToAccelerateJump() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "jump");
}

vec3 GetDodgeDirection() {
    return GetTargetVelocity();
}

bool WantsToDodge(const Timestep &in ts) {
    if(!this_mo.controlled) return false;
    vec3 targ_vel = GetTargetVelocity();
    bool movement_key_down = false;
    if(length_squared(targ_vel) > 0.1f){
        movement_key_down = true;
    }
    return movement_key_down;
}

bool WantsToCancelAnimation() {
    return GetInputDown(this_mo.controller_id, "jump") || 
           GetInputDown(this_mo.controller_id, "crouch") ||
           GetInputDown(this_mo.controller_id, "grab") ||
           GetInputDown(this_mo.controller_id, "attack") ||
           GetInputDown(this_mo.controller_id, "move_up") ||
           GetInputDown(this_mo.controller_id, "move_left") ||
           GetInputDown(this_mo.controller_id, "move_right") ||
           GetInputDown(this_mo.controller_id, "move_down");
}

// Converts the keyboard controls into a target velocity that is used for movement calculations in aschar.as and aircontrol.as.
vec3 GetTargetVelocity() {
    vec3 target_velocity(0.0f);
    if(!this_mo.controlled) return target_velocity;
    
    vec3 right;
    {
        right = camera.GetFlatFacing();
        float side = right.x;
        right.x = -right .z;
        right.z = side;
    }

    target_velocity -= GetMoveYAxis(this_mo.controller_id)*camera.GetFlatFacing();
    target_velocity += GetMoveXAxis(this_mo.controller_id)*right;

    if(length_squared(target_velocity)>1){
        target_velocity = normalize(target_velocity);
    }
    
    if(trying_to_get_weapon > 0){
        target_velocity = get_weapon_dir;
    }
    dir_x = target_velocity.x;
    dir_z = target_velocity.z;

    return target_velocity;
}

// Called from aschar.as, bool front tells if the character is standing still. Only characters that are standing still may perform a front kick.
void ChooseAttack(bool front) {
    curr_attack = "";
    if(on_ground){
        if(!WantsToCrouch()){
            if(front){
                curr_attack = "stationary";            
            } else {
                curr_attack = "moving";
            }
        } else {
            curr_attack = "low";
        }    
    } else {
        curr_attack = "air";
    }
}

WalkDir WantsToWalkBackwards() {
    return FORWARDS;
}

bool WantsReadyStance() {
    return true;
}

int CombatSong() {
    return situation.PlayCombatSong()?1:0;
}

int IsAggressive() {
    return 0;
}
