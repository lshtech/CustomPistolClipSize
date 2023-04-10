class X2DownloadableContentInfo_CustomPistolClipSize extends X2DownloadableContentInfo config(PistolClip);

static event OnPostTemplatesCreated()
{
	UpdateEventListener();
	AddPistolClipLabel();
}

static function AddPistolClipLabel()
{
	local X2ItemTemplateManager 		ItemTemplateMgr;
	local array<X2DataTemplate> 		DataTemplates;
	local X2DataTemplate 				DataTemplate;
	local X2WeaponTemplate				WeaponTemplate;
	local int							ClipSize;
	
	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach ItemTemplateMgr.IterateTemplates(DataTemplate, none)
	{
		WeaponTemplate = X2WeaponTemplate(DataTemplate);
		if (WeaponTemplate != none && (WeaponTemplate.WeaponCat == 'pistol' || WeaponTemplate.WeaponCat == 'sidearm' ))
		{
			ClipSize = WeaponTemplate.iClipSize;
			if (ClipSize == 99 || ClipSize == 0)
				ClipSize = 6;
				
			WeaponTemplate.SetUIStatMarkup(class'XLocalizedData'.default.ClipSizeLabel, , ClipSize);
		}
	}
}

static function UpdateEventListener()
{
	local X2EventListenerTemplateManager EventTemplateManager;
	local CHEventListenerTemplate EventTemplate;

	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

	EventTemplate = CHEventListenerTemplate(EventTemplateManager.FindEventListenerTemplate('PrimarySecondariesOverrideClipSizeListener'));

	if(EventTemplate != none)
	{
		EventTemplate.RemoveEvent('OverrideClipSize');
		EventTemplate.AddCHEvent('OverrideClipSize', OnOverrideClipSize, ELD_Immediate);
	}
}

static function EventListenerReturn OnOverrideClipSize(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Item ItemState;
	local XComLWTuple Tuple;
	local X2WeaponTemplate Template;

	Tuple = XComLWTuple(EventData);
	ItemState = XComGameState_Item(EventSource);

	if (ItemState == none)
	{
		return ELR_NoInterrupt;
	}

	if (class'LoadoutApiFactory'.static.GetLoadoutApi().IsSecondaryPistolItem(ItemState))
	{
		Tuple.Data[0].i = 99;
	}
	else if (class'LoadoutApiFactory'.static.GetLoadoutApi().IsPrimaryPistolItem(ItemState))
	{
		Template = X2WeaponTemplate(ItemState.GetMyTemplate());
		if (Template != none && Template.iClipSize > 0 && Template.iClipSize < 99)
			Tuple.Data[0].i = Template.iClipSize;
		else
			Tuple.Data[0].i = class'X2DownloadableContentInfo_TruePrimarySecondaries'.default.PRIMARY_PISTOLS_CLIP_SIZE;
	}

	return ELR_NoInterrupt;
}