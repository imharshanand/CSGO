//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//- v1.4.1 --------------------------------------------------------------
IncludeScript("vs_library");

// don't overwrite
if(!("_BM_"in getroottable()))
	::_BM_ <- { _VER_ = "1.4.1" };;

class::V
{
	constructor(_x=0,_y=0,_z=0)
	{
		x = _x;
		y = _y;
		z = _z;
	}

	function V(dx=0,dy=0,dz=0)return::Vector(x+dx,y+dy,z+dz);

	x = 0.0;
	y = 0.0;
	z = 0.0;
}

try(IncludeScript("benchmark_res",_BM_))
catch(e)
{
	return Msg("ERROR: Could not find the benchmark resource file.\n");
}

// aliases
SendToConsole("alias benchmark\"script _BM_.Start()\";alias bm_stop\"script _BM_.Stop()\";alias bm_rec\"script _BM_.Record()\";alias bm_timer\"script _BM_.ToggleCounter()\";alias bm_setup\"script _BM_.PrintSetupCmd()\";alias bm_list\"script _BM_.ListSetupData()\";alias bm_clear\"script _BM_.ClearSetupData()\";alias bm_remove\"script _BM_.RemoveSetupData()\"");

SendToConsole("alias bm_mdl\"script _BM_.PrintMDL()\";alias bm_mdl1\"script _BM_.PrintMDL(1)\";alias bm_flash\"script _BM_.PrintFlash()\";alias bm_flash1\"script _BM_.PrintFlash(1)\";alias bm_he\"script _BM_.PrintHE()\";alias bm_he1\"script _BM_.PrintHE(1)\";alias bm_molo\"script _BM_.PrintMolo()\";alias bm_molo1\"script _BM_.PrintMolo(1)\";alias bm_smoke\"script _BM_.PrintSmoke()\";alias bm_smoke1\"script _BM_.PrintSmoke(1)\";alias bm_expl\"script _BM_.PrintExpl()\";alias bm_expl1\"script _BM_.PrintExpl(1)\"\"");

//--------------------------------------------------------------

SendToConsole("clear;script _BM_.PostSpawn()");

VS.GetLocalPlayer();

// don't overwrite
if(!("bStarted" in _BM_))
{
	_BM_.FTIME <- 0.015625;
	_BM_.Msg <- printl;
	_BM_.fTickrate <- VS.GetTickrate();
	_BM_.sMapName <- split(GetMapName(),"/").top();
	_BM_.bStartedPending <- false;
	_BM_.bStarted <- false;
	_BM_.flTimeStart <- 0.0;
	_BM_.iDev <- 0;
	_BM_.iRecLast <- 0;
	_BM_.nCounterCount <- 0;
	_BM_.list_models <- [];
	_BM_.list_nades <- [];
};;

if( !("hThink" in _BM_) )
{
	_BM_.hStrip <- VS.CreateEntity("game_player_equip",{ spawnflags = 1<<1 },1).weakref();
	_BM_.hHudHint <- VS.CreateEntity("env_hudhint",null,1).weakref();
	_BM_.hCam <- VS.CreateEntity("point_viewcontrol",{ spawnflags = 1<<3 }).weakref();
	_BM_.hThink <- VS.Timer(1,_BM_.FTIME,null,null,1,1).weakref();
	_BM_.hCounter <- VS.Timer(1,1,null,null,0,1).weakref();

	// init vars
	local sc = _BM_.hThink.GetScriptScope();
	sc.cam <- _BM_.hCam.weakref();
	sc.pos <- null;
	sc.ang <- null;
	sc.lim <- null;
	sc.idx <- 0;
};;

//--------------------------------------------------------------

// Process large data by splitting it into chunks, recursively process the chunks
function _BM_::__LoadData()
{
	local c1 = "l_" + sMapName;

	if( !(c1 in this) )
		return __LoadData_clf();

	local data = this[c1];

	if( !("pos" in data) || !("ang" in data) || !data.pos.len() || !data.ang.len() )
		return __LoadData_clf();

	_data <- data.weakref();
	_LIM <- data.pos.len();
	_STP <- 1450;
	_IDX <- 0;
	_CMX <- ::clamp(_STP, 0, _LIM);

	__LoadData_pos();
}

function _BM_::__LoadData_pos()
{
	local lp = _data.pos;

	for( local i = _IDX; i < _CMX; ++i )
		lp[i] = lp[i].V();

	_IDX += _STP;
	_CMX = ::clamp(_CMX + _STP, 0, _LIM);

	// next
	if( _IDX >= _CMX )
	{
		_IDX = 0;
		_CMX = ::clamp(_STP, 0, _LIM);
		return __LoadData_ang();
	};

	return::delay("::_BM_.__LoadData_pos()", FTIME);
}

function _BM_::__LoadData_ang()
{
	local la = _data.ang;

	for( local i = _IDX; i < _CMX; ++i )
		la[i] = la[i].V();

	_IDX += _STP;
	_CMX = ::clamp(_CMX + _STP, 0, _LIM);

	// complete
	if( _IDX >= _CMX )
	{
		delete _LIM;
		delete _STP;
		delete _IDX;
		delete _CMX;
		__LoadData_load(delete _data);
		return __LoadData_clf();
	};

	return::delay("::_BM_.__LoadData_ang()", FTIME);
}

function _BM_::__LoadData_load(data)
{
	// this can be done here because this script will only play the benchmark data,
	// which can only be loaded by reloading the whole script
	local sc = hThink.GetScriptScope();
	sc.pos = data.pos;
	sc.ang = data.ang;
	sc.lim = data.pos.len();
}

// clear functions
function _BM_::__LoadData_clf()
{
	delete __LoadData;
	delete __LoadData_pos;
	delete __LoadData_ang;
	delete __LoadData_clf;
	delete __LoadData_load;
}

//--------------------------------------------------------------

function _BM_::PlaySound(s) ::HPlayer.EmitSound(s);
function _BM_::Hint(s) ::VS.ShowHudHint(hHudHint,::HPlayer,s);

function _BM_::ToggleCounter(i = null)
{
	// toggle
	if( i == null )
		i = !hCounter.GetTeam();

	hCounter.SetTeam(i.tointeger());
	nCounterCount = 0;

	::EntFireByHandle(hCounter, i ? "enable" : "disable");
}

VS.OnTimer(_BM_.hCounter, function()
{
	Hint(++nCounterCount);
	PlaySound("UIPanorama.container_countdown");
},_BM_);

VS.OnTimer(_BM_.hThink,function()
{
	cam.SetOrigin(pos[idx]);
	local a = ang[idx];
	cam.SetAngles(a.x,a.y,a.z);
	if( ++idx >= lim )
		::_BM_.Stop(1);
},null,true);

function _BM_::Record()
{
	Msg("\nRecording is not available in the benchmark script.\nUse the keyframes script to create smooth paths:\n                github.com/samisalreadytaken/keyframes\n");
}

function _BM_::CheckData()
{
	local c1 = "l_" + sMapName;

	if( !(c1 in this) )
		return Msg("[!] Could not find map data for '" + sMapName + "'");

	local data = this[c1];

	if( !("pos" in data) || !("ang" in data) )
		return Msg("[!] Invalid map data!");

	if( !data.pos.len() || !data.ang.len() )
		return Msg("[!] Corrupted map data!");

	return data;
}

function _BM_::Start()
{
	if( bStartedPending )
		return Msg("Benchmark has not started yet.");

	if( bStarted )
		return Msg("Benchmark is already running!\nTo stop it: bm_stop");

	if( !CheckData() )
		return;

	// -------------------------------------------------------

	::EntFireByHandle(hThink, "disable");

	hThink.GetScriptScope().idx = 0;

	//--------------------------------------------------------------

	::EntFireByHandle(hStrip, "use", "", 0, ::HPlayer);
	::HPlayer.SetHealth(1337);

	if( "Setup_" + sMapName in this )
		this["Setup_" + sMapName]();

	bStartedPending = true;
	iDev = ::GetDeveloperLevel();

	//--------------------------------------------------------------

	local _1 = "SendToConsole(\"+quickinv\")",_0 = "SendToConsole(\"-quickinv\")";
	::delay( _1, 0.0 );::delay( _0, 0.1 );
	::delay( _1, 0.2 );::delay( _0, 0.3 );
	::delay( _1, 0.4 );::delay( _0, 0.5 );

	::delay("::_BM_.Hint(\"Starting in 3...\");::_BM_.PlaySound(\"Alert.WarmupTimeoutBeep\")", 0.5);
	::delay("::_BM_.Hint(\"Starting in 2...\");::_BM_.PlaySound(\"Alert.WarmupTimeoutBeep\")", 1.5);
	::delay("::_BM_.Hint(\"Starting in 1...\");::_BM_.PlaySound(\"Alert.WarmupTimeoutBeep\")", 2.5);
	::delay("::_BM_.Hint(\"Started...\")", 3.5);

	::delay("::_BM_.PlaySound(\"Weapon_AWP.BoltForward\")", 0.5);
	PlaySound("Weapon_AWP.BoltBack");

	//--------------------------------------------------------------

	::SendToConsole("r_cleardecals;clear;echo;echo;echo;echo\"   Starting in 3 seconds.\";echo;echo\"   Keep the console closed for higher FPS\";echo;echo;echo;developer 0;toggleconsole;fadeout");

	::delay("::_BM_._Start()", 3.5);
}

function _BM_::_Start()
{
	bStartedPending = false;
	bStarted = true;
	flTimeStart = ::Time();
	::EntFireByHandle(hCam, "enable", "", 0, ::HPlayer);
	::EntFireByHandle(hThink, "enable");
	::SendToConsole("fadein;fps_max 0;bench_start;bench_end;clear;echo;echo;echo;echo\"   Benchmark has started\";echo;echo\"   Keep the console closed for higher FPS\";echo;echo");
}

// i == 0 : force stopped
// i == 1 : path completed
function _BM_::Stop(i = 0)
{
	if( !bStarted )
		return Msg("Benchmark is not running.");

	if( bStartedPending )
		return Msg("Benchmark is about to start.");

	bStarted = false;

	::EntFireByHandle(hCam, "disable", "", 0, ::HPlayer);
	::EntFireByHandle(hThink, "disable");
	ToggleCounter(0);

	::SendToConsole("host_timescale 1;clear;echo;echo;echo;echo\"----------------------------\";echo;echo " +

		( i ? "Benchmark finished." :
		"Stopped benchmark.;echo;mp_restartgame 1;toggleconsole" )

	+";echo;echo\"Map: " + sMapName + "\";echo\"Tickrate: "+ fTickrate + "\";echo;toggleconsole" + ";echo\"Time: " + (::Time()-flTimeStart) + " seconds\";echo;bench_end;echo;echo\"----------------------------\";echo;echo;developer " + iDev);

	if(i) PlaySound("Buttons.snd9");
	PlaySound("UIPanorama.gameover_show");

	::Chat(txt.orange + "● "+txt.grey + "Results are printed in the console.");
	Hint("Results are printed in the console.");
}

function _BM_::PostSpawn()
{
	__LoadData();

	if( ::HPlayer.GetTeam() != 2 && ::HPlayer.GetTeam() != 3 )
		::HPlayer.SetTeam(2);

	PlaySound("Player.DrownStart");

	::ClearChat();
	::ClearChat();
	::Chat(::txt.blue+" --------------------------------");
	::Chat("");
	::Chat(::txt.lightgreen + "[Benchmark Script v"+_VER_+"]");
	::Chat(::txt.orange + "● " + ::txt.grey +"Server tickrate: " + ::txt.yellow + fTickrate);
	::Chat("");
	::Chat(::txt.blue+" --------------------------------");

	// print after Steamworks Msg
	if( ::GetDeveloperLevel() > 0 )
		::delay("SendToConsole(\"clear;script _BM_.WelcomeMsg()\")", 0.75);
	else WelcomeMsg();

	delete PostSpawn;
}

function _BM_::WelcomeMsg()
{
//Msg(@"
//
//                github.com/samisalreadytaken/csgo-benchmark
//
//Console commands:
//
//benchmark  : Run the benchmark
//bm_stop    : Force stop the ongoing benchmark
//           :
//bm_setup   : Print setup related commands
//
//----------
//
//Commands to display FPS:
//
//cl_showfps 1
//net_graph 1
//
//----------
//
//[i] The benchmark sets your fps_max to 0
//")

	Msg("\n\n\n   [v"+_VER_+"]     github.com/samisalreadytaken/csgo-benchmark\n\nConsole commands:\n\nbenchmark  : Run the benchmark\nbm_stop    : Force stop the ongoing benchmark\n           :\nbm_setup   : Print setup related commands\n\n----------\n\nCommands to display FPS:\n\ncl_showfps 1\nnet_graph 1\n\n----------\n\n[i] The benchmark sets your fps_max to 0\n");
	Msg("[i] Map: " + sMapName);
	Msg("[i] Server tickrate: " + fTickrate + "\n\n");

	if( !VS.IsInteger(128.0/fTickrate) )
	{
		Msg("[!] Invalid tickrate (" + fTickrate + ")! Only 128 and 64 ticks are supported.");
		Chat(txt.red+"[!] "+txt.white+"Invalid tickrate ( " +txt.yellow+ fTickrate +txt.white+" )! Only 128 and 64 ticks are supported.");
	};

	if( !CheckData() )
		Msg("\n");

	delete WelcomeMsg;
}

// bm_setup
function _BM_::PrintSetupCmd()
{
//Msg(@"
//
//   [v"+_VER_+"]     github.com/samisalreadytaken/csgo-benchmark
//
//bm_timer   : Toggle counter
//           :
//bm_list    : Print saved setup data
//bm_clear   : Clear saved setup data
//bm_remove  : Remove the last added setup data
//           :
//bm_mdl     : Print and add to list SpawnMDL
//bm_flash   : Print and add to list SpawnFlash
//bm_he      : Print and add to list SpawnHE
//bm_molo    : Print and add to list SpawnMolotov
//bm_smoke   : Print and add to list SpawnSmoke
//bm_expl    : Print and add to list SpawnExplosion
//           :
//bm_mdl1    : Spawn a playermodel
//bm_flash1  : Spawn a flashbang
//bm_he1     : Spawn an HE
//bm_molo1   : Spawn a molotov
//bm_smoke1  : Spawn smoke
//bm_expl1   : Spawn a C4 explosion
//
//For creating paths, use the keyframes script.
//                github.com/samisalreadytaken/keyframes
//
//")

	Msg("\n   [v"+_VER_+"]     github.com/samisalreadytaken/csgo-benchmark\n\nbm_timer   : Toggle counter\n           :\nbm_list    : Print saved setup data\nbm_clear   : Clear saved setup data\nbm_remove  : Remove the last added setup data\n           :\nbm_mdl     : Print and add to list SpawnMDL\nbm_flash   : Print and add to list SpawnFlash\nbm_he      : Print and add to list SpawnHE\nbm_molo    : Print and add to list SpawnMolotov\nbm_smoke   : Print and add to list SpawnSmoke\nbm_expl    : Print and add to list SpawnExplosion\n           :\nbm_mdl1    : Spawn a playermodel\nbm_flash1  : Spawn a flashbang\nbm_he1     : Spawn an HE\nbm_molo1   : Spawn a molotov\nbm_smoke1  : Spawn smoke\nbm_expl1   : Spawn a C4 explosion\n\nFor creating paths, use the keyframes script.\n                github.com/samisalreadytaken/keyframes\n\n");
}

// bm_clear
function _BM_::ClearSetupData()
{
	PlaySound("UIPanorama.XP.Ticker");
	list_models.clear();
	list_nades.clear();
	Msg("Cleared saved setup data.");
}

// bm_remove
function _BM_::RemoveSetupData()
{
	PlaySound("UIPanorama.XP.Ticker");
	if( !iRecLast )
	{
		if( !list_models.len() )
			return Msg("No saved data found.");
		list_models.pop();
		Msg("Removed the last added setup data. (model)");
	}
	else
	{
		if( !list_nades.len() )
			return Msg("No saved data found.");
		list_nades.pop();
		Msg("Removed the last added setup data. (nade)");
	};
}

// bm_list
function _BM_::ListSetupData()
{
	PlaySound("UIPanorama.XP.Ticker");

	if( !list_nades.len() && !list_models.len() )
		return Msg("No saved data found.");

	Msg("//------------------------\n// Copy the lines below:\n\n");
	Msg("function Setup_"+sMapName+"()\n{");
	foreach(k in list_models)Msg("\t"+k);
	Msg("");
	foreach(k in list_nades)Msg("\t"+k);
	Msg("}\n");
	Msg("\n//------------------------");
}

// bm_mdl
function _BM_::PrintMDL( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnMDL( "+VecToString(HPlayer.GetOrigin())+","+HPlayer.GetAngles().y+", MDL.ST6k )";

	if(i)
	{
		local p = HPlayer.GetOrigin();
		p.z += 72;
		HPlayer.SetOrigin(p);
		return compilestring(a)();
	};

	list_models.append(a);
	Msg("\n"+a);
	iRecLast = 0;
}

// bm_flash
function _BM_::PrintFlash( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnFlash( "+VecToString(HPlayer.GetOrigin())+", 0.0 )";

	if(i)
	{
		local p = HPlayer.GetOrigin();
		if( !HPlayer.IsNoclipping() ) p.z += 32;
		HPlayer.SetOrigin(p);
		return compilestring(a)();
	};

	list_nades.append(a);
	Msg("\n"+a);
	iRecLast = 1;
}

// bm_he
function _BM_::PrintHE( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnHE( "+VecToString(HPlayer.GetOrigin())+", 0.0 )";

	if(i)
	{
		local p = HPlayer.GetOrigin();
		if( !HPlayer.IsNoclipping() ) p.z += 32;
		HPlayer.SetOrigin(p);
		return compilestring(a)();
	};

	list_nades.append(a);
	Msg("\n"+a);
	iRecLast = 1;
}

// bm_molo
function _BM_::PrintMolo( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnMolotov( "+VecToString(HPlayer.GetOrigin())+", 0.0 )";

	if(i)
	{
		local p = HPlayer.GetOrigin();
		if( !HPlayer.IsNoclipping() ) p.z += 32;
		HPlayer.SetOrigin(p);
		return compilestring(a)();
	};

	list_nades.append(a);
	Msg("\n"+a);
	iRecLast = 1;
}

// bm_smoke
function _BM_::PrintSmoke( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnSmoke( "+VecToString(HPlayer.GetOrigin())+", 0.0 )";

	if(i) return compilestring(a)();

	list_nades.append(a);
	Msg("\n"+a);
	iRecLast = 1;
}

// bm_expl
function _BM_::PrintExpl( i = 0 )
{
	PlaySound("UIPanorama.XP.Ticker");
	local a = "SpawnExplosion( "+VecToString(HPlayer.GetOrigin())+", 0.0 )";

	if(i) return compilestring(a)();

	list_nades.append(a);
	Msg("\n"+a);
	iRecLast = 1;
}

function _BM_::__Spawn( v, t )
{
	for( local e; e = Entities.FindByClassname(e,t+"_projectile"); )
	{
		e.SetOrigin(v);
		EntFireByHandle(e,"initializespawnfromworld");
	}
}

function _BM_::SpawnFlash( v, d )
{
	delay("SendToConsole(\"ent_create flashbang_projectile;script _BM_.__Spawn("+VecToString(v)+",\\\"flashbang\\\")\")", d);
}

function _BM_::SpawnHE( v, d )
{
	delay("SendToConsole(\"ent_create hegrenade_projectile;script _BM_.__Spawn("+VecToString(v)+",\\\"hegrenade\\\")\")", d);
}

function _BM_::SpawnMolotov( v, d )
{
	delay("SendToConsole(\"ent_create molotov_projectile;script _BM_.__Spawn("+VecToString(v)+",\\\"molotov\\\")\")", d);
}

function _BM_::SpawnSmoke( v, d )
{
	delay("local v=" + VecToString(v) + ";DispatchParticleEffect(\"explosion_smokegrenade\",v,Vector(1,0,0));::_BM_.hCounter.SetOrigin(v);::_BM_.hCounter.EmitSound(\"BaseSmokeEffect.Sound\")", d);
}

function _BM_::SpawnExplosion( v, d )
{
	delay("local v=" + VecToString(v) + ";DispatchParticleEffect(\"explosion_c4_500\",v,Vector());::_BM_.hCounter.SetOrigin(v);::_BM_.hCounter.EmitSound(\"c4.explode\")", d);
}

function _BM_::SpawnMDL( v, a, m, p = 0 )
{
	if( !Entities.FindByClassnameNearest( "prop_dynamic_override", v, 1 ) )
	{
		PrecacheModel( m );
		local h = CreateProp( "prop_dynamic_override", v, m, 0 );
		h.SetAngles( 0, a, 0 );
		h.__KeyValueFromInt( "solid", 2 );
		h.__KeyValueFromInt( "disablebonefollowers", 1 );
		h.__KeyValueFromInt( "holdanimation", 1 );
		h.__KeyValueFromString( "defaultanim", "grenade_deploy_03" );

		switch( p )
		{
			case POSE.ROM:
				EntFireByHandle( h, "setanimation", "rom" );
				break;
			case POSE.A:
				h.SetAngles( 0, a + 90, 90 );
				EntFireByHandle( h, "setanimation", "additive_posebreaker" );
				break;
			case POSE.PISTOL:
				EntFireByHandle( h, "setanimation", "pistol_deploy_02" );
				break;
			case POSE.RIFLE:
				EntFireByHandle( h, "setanimation", "rifle_deploy" );
				break;
			default:
				EntFireByHandle( h, "setanimation", "grenade_deploy_03" );
				EntFireByHandle( h, "setplaybackrate", "0" );
		};
	};
}
