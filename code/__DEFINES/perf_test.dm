/// Macro that takes a tick usage to target, and proceses until we hit it
/// This lets us simulate generic load as we'd like, to make testing for overtime easier
#define CONSUME_UNTIL(target_usage) \
	while(TICK_USAGE < (target_usage)) {\
		var/_knockonwood_x = 0;\
		_knockonwood_x += 20;\
	}


