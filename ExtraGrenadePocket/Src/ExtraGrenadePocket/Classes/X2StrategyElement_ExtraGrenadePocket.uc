class X2StrategyElement_ExtraGrenadePocket extends CHItemSlotSet config(GameData);

struct GrenadePocketUnlock
{
	var name 	AbilityName;
	var int		MaxSlots;
};

var localized string 					strSlotFirstLetter;
var config array<name> 					AbilityUnlocksExtraGrenadePocket;
var config array<GrenadePocketUnlock>	MultipleAbilityUnlocksExtraGrenadePocket;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSlotTemplate());

	return Templates;
}

static function X2DataTemplate CreateSlotTemplate()
{
	local CHItemSlot Template;

	`CREATE_X2TEMPLATE(class'CHItemSlot', Template, 'ExtraGrenadePocketSlot');

	Template.InvSlot = eInvSlot_ExtraGrenadePocket;
	Template.SlotCatMask = Template.SLOT_ITEM;

	Template.IsUserEquipSlot = true;
	Template.IsEquippedSlot = false;

	Template.BypassesUniqueRule = true;
	Template.IsSmallSlot = true;
	Template.NeedsPresEquip = false;
	Template.ShowOnCinematicPawns = false;

	Template.CanAddItemToSlotFn = CanAddItemToSlot;

	Template.UnitHasSlotFn = HasSlot;
	Template.GetPriorityFn = SlotGetPriority;	
	
	Template.ShowItemInLockerListFn = ShowItemInLockerList;
	Template.ValidateLoadoutFn = SlotValidateLoadout;
	Template.GetSlotUnequipBehaviorFn = SlotGetUnequipBehavior;
	Template.GetDisplayNameFn = GetDisplayName;

	Template.IsMultiItemSlot = true;
	Template.MinimumEquipped = -1;
	Template.GetMaxItemCountFn = SlotGetMaxItemCount;
	Template.GetBestGearForSlotFn = GetBestGearForSlot;

	return Template;
}

static function int SlotGetMaxItemCount(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	local int MaxSlots, i, Slots;
	local array<name> CheckedAbilities;
	local bool hasAbility;

	MaxSlots = GetMaxPossibleSlots();
	Slots = 0;

	for (i = 1; i <= MaxSlots; i++)
	{			
		do
		{
			hasAbility = false;
			if (Slots < i && HasUnlockByMaxSlot(UnitState, i, CheckedAbilities))
			{
				hasAbility = true;
				Slots++;
			}
		} until (!hasAbility);
	}

	return Slots;
}

static function int GetMaxPossibleSlots()
{
	local int 					MaxSlots;
	local GrenadePocketUnlock 	Unlocks;

	MaxSlots = 1;
	
	foreach default.MultipleAbilityUnlocksExtraGrenadePocket(Unlocks)
	{
		if (Unlocks.MaxSlots > MaxSlots)
			MaxSlots = Unlocks.MaxSlots;
	}

	return MaxSlots;
}

static function bool HasUnlockByMaxSlot(XComGameState_Unit UnitState, int maxSlot, array<name> CheckedAbilities)
{
	local GrenadePocketUnlock 	Unlocks;

	if (maxSlot == 1 && UnitState.HasAnyOfTheAbilitiesFromAnySource(default.AbilityUnlocksExtraGrenadePocket))
		return true;

	foreach default.MultipleAbilityUnlocksExtraGrenadePocket(Unlocks)
	{
		if (Unlocks.MaxSlots == maxSlot && UnitState.HasAbilityFromAnySource(Unlocks.AbilityName) && CheckedAbilities.Find(Unlocks.AbilityName) == INDEX_NONE)
		{
			CheckedAbilities.AddItem(Unlocks.AbilityName);
			return true;
		}			
	}

	return false;
}

static function bool HasSlot(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState)
{
	local GrenadePocketUnlock 	Unlocks;

	if (UnitState.HasAnyOfTheAbilitiesFromAnySource(default.AbilityUnlocksExtraGrenadePocket))
		return true;

	foreach default.MultipleAbilityUnlocksExtraGrenadePocket(Unlocks)
	{
		if (UnitState.HasAbilityFromAnySource(Unlocks.AbilityName))
			return true;
	}

	return false;
}

static function bool ShowItemInLockerList(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, X2ItemTemplate ItemTemplate, XComGameState CheckGameState)
{
	return IsItemValidGrenadeOrRocket(ItemTemplate);
}

static function bool CanAddItemToSlot(CHItemSlot Slot, XComGameState_Unit UnitState, X2ItemTemplate ItemTemplate, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState)
{    
	return IsItemValidGrenadeOrRocket(ItemTemplate);
}

private static function bool IsItemValidGrenadeOrRocket(const X2ItemTemplate ItemTemplate)
{
	local X2GrenadeTemplate GrenadeTemplate;

	GrenadeTemplate = X2GrenadeTemplate(ItemTemplate);

	return GrenadeTemplate != none;
}

static function array<X2EquipmentTemplate> GetBestGearForSlot(CHItemSlot Slot, XComGameState_Unit Unit)
{
	local array<X2EquipmentTemplate>	arr;
	local X2EquipmentTemplate			ClawsTemplate;

	ClawsTemplate = X2EquipmentTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate('FragGrenade'));

	arr.AddItem(ClawsTemplate);

	return arr;
}

static function SlotValidateLoadout(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> ItemStates;
	local string strDummy;
	local bool HasSlot;
	local int i, iMaxItems;

	ItemStates = Unit.GetAllItemsInSlot(Slot.InvSlot, NewGameState);
	HasSlot = Slot.UnitHasSlot(Unit, strDummy, NewGameState);

	iMaxItems = Slot.GetMaxItemCountFn(Slot, Unit, NewGameState);

	//	Unit has slot
	if (HasSlot)
	{
		//	... but not enough items equipped. 
		for (i = ItemStates.Length; i < iMaxItems; i++)
		{
			ItemState = FindBestWeapon(Unit, Slot.InvSlot, XComHQ, NewGameState);
			if (ItemState != none)
			{
				Unit.AddItemToInventory(ItemState, Slot.InvSlot, NewGameState);
			}
			else return;	//	Could not find a weapon to put into the slot - exit.
		}	

		//	... but too many items equipped.
		for (i = ItemStates.Length; i > iMaxItems; i--)
		{
			ItemState = ItemStates[i];

			ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));
			if (ItemState != none)
			{
				if (Unit.RemoveItemFromInventory(ItemState, NewGameState))
				{
					//`LOG("Successfully unequipped the item. Putting it into HQ Inventory.",, 'WOTCMoreSparkWeapons');
					XComHQ.PutItemInInventory(NewGameState, ItemState);
				}
			}
		}	
		
		return; // All done equipping or unequipping items into the slot, exit.
	}

	//	Unit doesn't have the slot, but has some items equipped into it.
	if (ItemStates.Length > 0 && !HasSlot)
	{
		foreach ItemStates(ItemState)
		{
			ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));

			if (Unit.RemoveItemFromInventory(ItemState, NewGameState))
			{
				XComHQ.PutItemInInventory(NewGameState, ItemState);
			}
		}
	}
}

private static function XComGameState_Item FindBestWeapon(const XComGameState_Unit UnitState, EInventorySlot Slot, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local X2GrenadeTemplate					GrenadeTemplate;
	local XComGameStateHistory				History;
	local int								HighestTier;
	local XComGameState_Item				ItemState;
	local XComGameState_Item				BestItemState;
	local StateObjectReference				ItemRef;

	HighestTier = -999;
	History = `XCOMHISTORY;

	//	Cycle through all items in HQ Inventory
	foreach XComHQ.Inventory(ItemRef)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
		if (ItemState != none)
		{
			GrenadeTemplate = X2GrenadeTemplate(ItemState.GetMyTemplate());

			//	If this is an infinite item, it's tier is higher than the current recorded highest tier,
			//	it is allowed on the soldier by config entries that are relevant to this soldier
			//	and it can be equipped on the soldier
			if (GrenadeTemplate != none && GrenadeTemplate.bInfiniteItem && GrenadeTemplate.Tier > HighestTier && 
				UnitState.CanAddItemToInventory(GrenadeTemplate, Slot, NewGameState, ItemState.Quantity, ItemState))
			{	
				//	then remember this item as the currently best replacement option.
				HighestTier = GrenadeTemplate.Tier;
				BestItemState = ItemState;
			}
		}
	}

	if (BestItemState != none)
	{
		//	This will set up the Item State for modification automatically, or create a new Item State in the NewGameState if the template is infinite.
		XComHQ.GetItemFromInventory(NewGameState, BestItemState.GetReference(), BestItemState);
	}

	//	If we didn't find any fitting items, then BestItemState will be "none", and we're okay with that.
	return BestItemState;
}

function ECHSlotUnequipBehavior SlotGetUnequipBehavior(CHItemSlot Slot, ECHSlotUnequipBehavior DefaultBehavior, XComGameState_Unit UnitState, XComGameState_Item ItemState, optional XComGameState CheckGameState)
{	
	return eCHSUB_AttemptReEquip;
}

static function int SlotGetPriority(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return 105;
}

static function string GetDisplayName(CHItemSlot Slot)
{
	return class'UIArmory_Loadout'.default.m_strInventoryLabels[eInvSlot_GrenadePocket];
}
