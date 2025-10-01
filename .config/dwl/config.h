#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const int sloppyfocus               = 0;
static const int bypass_surface_visibility = 0;
static const unsigned int borderpx         = 1;
static const float rootcolor[]             = COLOR(0x222222ff);
static const float bordercolor[]           = COLOR(0x444444ff);
static const float focuscolor[]            = COLOR(0x005577ff);
static const float urgentcolor[]           = COLOR(0xff0000ff);
static const float fullscreen_bg[]         = {0.0f, 0.0f, 0.0f, 1.0f};

/* Swallow patch */
static int enableautoswallow = 1;
static float swallowborder = 0.0f;

/* Unclutter patch */
static const int cursor_timeout = 5;

/* Suppress unused warnings */
static inline void __suppress_warnings(void) {
	(void)enableautoswallow;
	(void)swallowborder;
	(void)cursor_timeout;
}

#define TAGCOUNT (9)

/* Master/Stack configuration */
static const int nmaster = 1;  /* Always show only 1 window in master area */

static int log_level = WLR_ERROR;

/* Autostart */
static const char *const autostart[] = {
	"mako", NULL,
	"kanshi", NULL,
	"sh", "-c", "swayidle -w timeout 300 'swaylock -f' before-sleep 'swaylock -f' lock 'swaylock -f'", NULL,
	"/usr/libexec/lxqt-policykit-agent", NULL,
	NULL /* terminate */
};

static const Rule rules[] = {
	/* app id             title       tags mask     isfloating   isterm   noswallow  monitor */
	{ "foot",             NULL,       0,            0,           1,       1,          -1 },
	{ "LibreWolf",        NULL,       0,            0,           0,       0,          -1 },
	{ "Chromium-browser", NULL,       0,            0,           0,       0,          -1 },
	{ "Brave-browser",    NULL,       0,            0,           0,       0,          -1 },
	{ "firefox",          NULL,       0,            0,           0,       0,          -1 },
	{ "firefox",          "Firefox — Sharing Indicator", 0, 1, 0, 0, -1 },
	
	/* System utilities - floating */
	{ "pavucontrol",      NULL,       0,            1,           0,       0,          -1 },
	{ "pavucontrol-qt",   NULL,       0,            1,           0,       0,          -1 },
	{ "nm-connection-editor", NULL,   0,            1,           0,       0,          -1 },
	{ "lxqt-policykit-agent", NULL,   0,            1,           0,       0,          -1 },
	{ "wdisplays",        NULL,       0,            1,           0,       0,          -1 },
};


static const Layout layouts[] = {
	{ "[]=",      tile },
	{ "><>",      NULL },
};

static const MonitorRule monrules[] = {
	{ NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,   -1,  -1 },
};

static const struct xkb_rule_names xkb_rules = {
	.options = NULL,
};

static const int repeat_rate = 25;
static const int repeat_delay = 600;

static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;

static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

#define MODKEY WLR_MODIFIER_LOGO

#define TAGKEYS(KEY,SKEY,TAG) \
	{ MODKEY,                    KEY,            view,            {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL,  KEY,            toggleview,      {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_SHIFT, SKEY,           tag,             {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT,SKEY,toggletag, {.ui = 1 << TAG} }

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

static const char *termcmd[] = { "foot", NULL };
static const char *menucmd[] = { "mybemenu", "--apps", NULL };
static const char *screentoolscmd[] = { "screen-tools", NULL };
static const char *powerctlcmd[] = { "power-manager", NULL };
static const char *clipmancmd[] = { "clipboard-manager", NULL };
static const char *passmancmd[] = { "password-manager", NULL };
static const char *sysinfocmd[] = { "system-info", NULL };
static const char *netmancmd[] = { "nm-connection-editor", NULL };
static const char *monmancmd[] = { "monitor-manager", NULL };


static const Key keys[] = {
	/* Applications */
	{ MODKEY,                    XKB_KEY_Return,     spawn,          {.v = termcmd} },
	{ WLR_MODIFIER_ALT,          XKB_KEY_p,          spawn,          {.v = menucmd} }, // App launcher (Alt+p)
	{ MODKEY,                    XKB_KEY_b,          spawn,          {.v = menucmd} }, // Browser alternative
	{ MODKEY,                    XKB_KEY_BackSpace,  spawn,          {.v = powerctlcmd} },

	/* Window Management */
	{ MODKEY,                    XKB_KEY_q,          killclient,     {0} },
	{ MODKEY,                    XKB_KEY_j,          focusstack,     {.i = +1} },
	{ MODKEY,                    XKB_KEY_k,          focusstack,     {.i = -1} },
	{ MODKEY,                    XKB_KEY_h,          setmfact,       {.f = -0.05f} },
	{ MODKEY,                    XKB_KEY_l,          setmfact,       {.f = +0.05f} },
	{ MODKEY,                    XKB_KEY_Tab,        view,           {0} },
	{ MODKEY,                    XKB_KEY_f,          togglefloating, {0} },
	{ MODKEY,                    XKB_KEY_e,          togglefullscreen, {0} },

	/* Layout Management */
	{ MODKEY,                    XKB_KEY_t,          setlayout,      {.v = &layouts[0]} }, // Tile
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_f,          setlayout,      {.v = &layouts[1]} }, // Floating

	/* Master Management */
	{ MODKEY,                    XKB_KEY_i,          incnmaster,     {.i = +1} },
	{ MODKEY,                    XKB_KEY_d,          incnmaster,     {.i = -1} },

	/* Monitor Management */
	{ MODKEY,                    XKB_KEY_o,          spawn,          {.v = monmancmd} },
	{ MODKEY,                    XKB_KEY_comma,      focusmon,       {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY,                    XKB_KEY_period,     focusmon,       {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_less,       tagmon,         {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_greater,    tagmon,         {.i = WLR_DIRECTION_RIGHT} },

	/* Custom Tools */
	{ MODKEY,                    XKB_KEY_v,          spawn,          {.v = clipmancmd} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_P,          spawn,          {.v = passmancmd} },
	{ MODKEY,                    XKB_KEY_s,          spawn,          {.v = sysinfocmd} },
	{ MODKEY,                    XKB_KEY_w,          spawn,          {.v = netmancmd} },

	/* Workspaces */
	{ MODKEY,                    XKB_KEY_0,          view,           {.ui = ~0} },
	{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_parenright, tag,            {.ui = ~0} },

	TAGKEYS(          XKB_KEY_1, XKB_KEY_exclam,                     0),
	TAGKEYS(          XKB_KEY_2, XKB_KEY_at,                         1),
	TAGKEYS(          XKB_KEY_3, XKB_KEY_numbersign,                 2),
	TAGKEYS(          XKB_KEY_4, XKB_KEY_dollar,                     3),
	TAGKEYS(          XKB_KEY_5, XKB_KEY_percent,                    4),
	TAGKEYS(          XKB_KEY_6, XKB_KEY_asciicircum,                5),
	TAGKEYS(          XKB_KEY_7, XKB_KEY_ampersand,                  6),
	TAGKEYS(          XKB_KEY_8, XKB_KEY_asterisk,                  7),
	TAGKEYS(          XKB_KEY_9, XKB_KEY_parenleft,                  8),
	
	{ 0,                          XKB_KEY_XF86MonBrightnessDown, spawn, SHCMD("brightnessctl -q set 5%- && notify-send -e -h string:x-canonical-private-synchronous:brightness -h 'int:value:$(brightnessctl --percentage get)' -t 800 'Brightness: $(brightnessctl --percentage get)%'") },
	{ 0,                          XKB_KEY_XF86MonBrightnessUp,   spawn, SHCMD("brightnessctl -q set +5% && notify-send -e -h string:x-canonical-private-synchronous:brightness -h 'int:value:$(brightnessctl --percentage get)' -t 800 'Brightness: $(brightnessctl --percentage get)%'") },
	{ 0,                          XKB_KEY_XF86AudioPlay,         spawn, SHCMD("playerctl play-pause") },
	{ 0,                          XKB_KEY_XF86AudioStop,         spawn, SHCMD("playerctl stop") },
	{ 0,                          XKB_KEY_XF86AudioForward,      spawn, SHCMD("playerctl position +10") },
	{ 0,                          XKB_KEY_XF86AudioNext,         spawn, SHCMD("playerctl next") },
	{ 0,                          XKB_KEY_XF86AudioPause,        spawn, SHCMD("playerctl pause") },
	{ 0,                          XKB_KEY_XF86AudioPrev,         spawn, SHCMD("playerctl previous") },
	{ 0,                          XKB_KEY_XF86AudioRewind,       spawn, SHCMD("playerctl position -10") },
	{ 0,                          XKB_KEY_XF86AudioRaiseVolume,  spawn, SHCMD("pactl set-sink-volume @DEFAULT_SINK@ +5%") },
	{ 0,                          XKB_KEY_XF86AudioLowerVolume,  spawn, SHCMD("pactl set-sink-volume @DEFAULT_SINK@ -5%") },
	{ 0,                          XKB_KEY_XF86AudioMute,         spawn, SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle") },
	{ 0,                          XKB_KEY_XF86AudioMicMute,      spawn, SHCMD("pactl set-source-mute @DEFAULT_SOURCE@ toggle") },
	
	{ 0,                          XKB_KEY_Print,                 spawn, {.v = screentoolscmd} },
	
	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_Terminate_Server, quit, {0} },
#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,XKB_KEY_XF86Switch_VT_##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};