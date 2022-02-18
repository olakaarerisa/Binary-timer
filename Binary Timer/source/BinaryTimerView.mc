//
// Copyright 2017-2021 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

//! The main view for the timer application. This displays the
//! remaining time on the countdown timer
(:typecheck(disableBackgroundCheck))
class BinaryTimerView extends WatchUi.View {
	
	var mainFont = null;
	var smallFont = null;
	
	public var rectangleMode = true;
	
    private enum TimerKeys {
        TIMER_KEY_DURATION,
        TIMER_KEY_START_TIME,
        TIMER_KEY_PAUSE_TIME
    }

    private const TIMER_DURATION_DEFAULT = (5 * 60);    // 5 minutes

    private var _timerDuration as Number;
    private var _timerStartTime as Number?;
    private var _timerPauseTime as Number?;
    private var _updateTimer as Timer.Timer;

    //! Initialize variables for this view
    //! @param backgroundRan Contains background data if background ran
    public function initialize(backgroundRan as PersistableType?) {
    	
    
        View.initialize();

        // Fetch the persisted values from storage
        if (backgroundRan == null) {
        	
            var timerDuration = Storage.getValue(TIMER_KEY_DURATION);
            if (timerDuration instanceof Number) {
                _timerDuration = timerDuration;
                
            } else {
                _timerDuration = TIMER_DURATION_DEFAULT;
               
            }
            _timerStartTime = Storage.getValue(TIMER_KEY_START_TIME);
            _timerPauseTime = Storage.getValue(TIMER_KEY_PAUSE_TIME);
        } else {
            // If we got an expiration event from the background process
            // when we started up, reset the timer back to the default value.
            _timerDuration = TIMER_DURATION_DEFAULT;
            _timerStartTime = null;
            _timerPauseTime = null;
        }

        // Create our timer object that is used to drive display updates
        _updateTimer = new Timer.Timer();

        // If the timer is running, we need to start the timer up now.
        if ((_timerStartTime != null) && (_timerPauseTime == null)) {
            // Update the display each second.
            _updateTimer.start(method(:requestUpdate), 1000, true);
        }
    }
    
    function onLayout(dc) {
    	mainFont = WatchUi.loadResource(Rez.Fonts.digitalBigFont);
       	smallFont = WatchUi.loadResource(Rez.Fonts.digitalSmallFont);
    	
    	System.println("With: " + dc.getWidth());
    }
    
	public function onShow() as Void {
		
		
		var timerDuration = Storage.getValue(TIMER_KEY_DURATION);
        if (timerDuration instanceof Number) {
        	_timerDuration = timerDuration;
           
        } else {
            _timerDuration = TIMER_DURATION_DEFAULT;
           
        }
        
		_timerStartTime = Storage.getValue(TIMER_KEY_START_TIME);
        _timerPauseTime = Storage.getValue(TIMER_KEY_PAUSE_TIME);
		

        // Create our timer object that is used to drive display updates
        _updateTimer = new Timer.Timer();

        // If the timer is running, we need to start the timer up now.
        if ((_timerStartTime != null) && (_timerPauseTime == null)) {
            // Update the display each second.
            _updateTimer.start(method(:requestUpdate), 1000, true);
        }
		
	}
	
	
    //! Draw the time remaining on the timer to the display
    //! @param dc Device Context
    public function onUpdate(dc as Dc) as Void {
        var textColor = Graphics.COLOR_WHITE;
		var clockTime = System.getClockTime();
        var elapsed = 0;
        var timerStartTime = _timerStartTime;
        if (timerStartTime != null) {
            var timerPauseTime = _timerPauseTime;
            if (timerPauseTime != null) {
                // Draw the time in yellow if the timer is paused
                textColor = Graphics.COLOR_YELLOW;
                elapsed = timerPauseTime - timerStartTime;
            } else {
                elapsed = Time.now().value() - timerStartTime;
            }

            if (elapsed >= _timerDuration) {
                elapsed = _timerDuration;
                // Draw the time in red if the timer has expired
                textColor = Graphics.COLOR_RED;
                _timerPauseTime = Time.now().value();
                _updateTimer.stop();
                if (Attention has :ToneProfile) {
    				var toneProfile =
    				[
        				new Attention.ToneProfile( 2500, 250),
        				new Attention.ToneProfile( 5000, 250),
        				new Attention.ToneProfile(10000, 250),
        				new Attention.ToneProfile( 5000, 250),
        				new Attention.ToneProfile( 2500, 250),
    				];
    				Attention.playTone({:toneProfile=>toneProfile});
				}
				
				if (Attention has :vibrate) {
                var vibrateData = [
                        new Attention.VibeProfile(25, 100),
                        new Attention.VibeProfile(50, 100),
                        new Attention.VibeProfile(75, 100),
                        new Attention.VibeProfile(100, 100),
                        new Attention.VibeProfile(75, 100),
                        new Attention.VibeProfile(50, 100),
                        new Attention.VibeProfile(25, 100)
                      ] as Array<VibeProfile>;

                Attention.vibrate(vibrateData);
                
                }
            }
        }
		
		var clockValue = clockTime.hour*3600 + clockTime.min*60 + clockTime.sec;
        var timerValue = _timerDuration - elapsed;
		
		
		var finishValue = clockValue + timerValue;
		
        var seconds = timerValue % 60;
        var minutes = timerValue / 60 % 60;
        var hours = timerValue / 3600;
        
        var hourFormat = "$1$$2$$3$$4$$5$";

        var hourString = Lang.format(hourFormat,
        	[
        	hours / 16 % 2,
        	hours / 8 % 2,
        	hours / 4 % 2,
        	hours / 2 % 2,
        	hours /1 % 2
        	]
        ); 
        
        var minuteFormat = "$1$$2$$3$$4$$5$$6$";

        var minuteString = Lang.format(minuteFormat,
        	[
        	minutes / 32 % 2,
        	minutes / 16 % 2,
        	minutes / 8 % 2,
        	minutes / 4 % 2,
        	minutes / 2 % 2,
        	minutes /1 % 2
        	]
        ); 
        
        var secondsFormat = "$1$$2$$3$$4$$5$$6$";

        var secondsString = Lang.format(secondsFormat,
        	[
        	seconds / 32 % 2,
        	seconds / 16 % 2,
        	seconds / 8 % 2,
        	seconds / 4 % 2,
        	seconds / 2 % 2,
        	seconds /1 % 2
        	]
        ); 
        
        var timeString = clockTime.hour + ":" + clockTime.min.format("%02d") + ":" + clockTime.sec.format("%02d");
        var countToString = (_timerDuration / 3600).format("%02d") + ":" + (_timerDuration / 60 % 60).format("%02d") + ":" + (_timerDuration % 60).format("%02d");
        //var timerString = minutes + ":" + seconds.format("%02d");
		var finishedString = (finishValue / 3600).format("%02d") + ":" + (finishValue / 60 % 60).format("%02d") + ":" + (finishValue % 60).format("%02d");
		
		var stats = System.getSystemStats();
        var pwr = (stats.battery + 0.5).toLong();
        var pwrString = pwr + "%";
        
        dc.setColor(textColor, Graphics.COLOR_BLACK);
        dc.clear();
        
        var pwrY = dc.getHeight()*0.05;
        var minY = dc.getHeight()/2;
        var secY = minY + dc.getFontHeight(mainFont)*0.79;
        var hourY = minY - dc.getFontHeight(mainFont)*0.79;
        var timeSetY = minY + dc.getFontHeight(mainFont) + dc.getFontHeight(smallFont);
        var clockY = minY - dc.getFontHeight(mainFont)- dc.getFontHeight(smallFont)*1.2;
        var finishedY = minY + dc.getFontHeight(mainFont) + dc.getFontHeight(smallFont)*2;
        var rest_width;
        var rest_height;
        var rectangle_width;
        var rectangle_height;
        //var minY = dc.getHeight()/2 - dc.getFontHeight(mainFont);
        System.println("minY: "+ minY);
        System.println("secY: " + secY);
        System.println("hourY: " + hourY);
        System.println("Font height: " + dc.getFontHeight(mainFont));
        
        
        if (rectangleMode == true) {
        	rest_width = (dc.getWidth() - 2) % 3;
       		if ((dc.getHeight() - 5) % 6 > 4) {
       			rest_height = 3;
       		} else if ((dc.getHeight() - 5) % 6 > 2) {
       			rest_height = 2;
       		} else {
       			rest_height = 1;
       		}
       		rectangle_width = (dc.getWidth()-2)/3 + rest_width;
       		rectangle_height = (dc.getHeight()-5)/6 + rest_height;
			
			
			
       		dc.setColor(textColor, Graphics.COLOR_BLACK);
       		//draw hourrectangles
    		for(var x = 0; x < 1; x ++) {
    			for(var y = 0; y < 6; y ++)	{
					dc.drawRectangle(x*(rectangle_width+1)-rest_width, y*(rectangle_height+1) - rest_height, rectangle_width, rectangle_height);
  				}
    		}
       		
       		//show hours
    		for(var i = 0; i < 5; i ++) {
    			if ( hours / (Math.pow(2,4-i).toLong()) % 2 == 1) {
    				dc.fillRectangle(-rest_width, (i+1)*(rectangle_height+1)-rest_height, rectangle_width, rectangle_height-1);
    			}
	    	}
    		
    		//draw minuterectangles
    		for(var x = 1; x < 2; x ++) {
    			for(var y = 0; y < 6; y ++)	{
					dc.drawRectangle(x*(rectangle_width+1)-rest_width, y*(rectangle_height+1) - rest_height, rectangle_width, rectangle_height);
  				}
    		}
    		//show minute
    		for(var i = 0; i < 6; i ++) {
    			if ( minutes / (Math.pow(2,5-i).toLong()) % 2 == 1) {
       				dc.fillRectangle(rectangle_width+1-rest_width, (i)*(rectangle_height+1)-rest_height, rectangle_width, rectangle_height-1);
    			}
    		}
    		
    		
    		//draw daterectangles
    		for(var x = 2; x < 3; x ++) {
    			for(var y = 0; y < 6; y ++)	{
					dc.drawRectangle(x*(rectangle_width+1)-rest_width, y*(rectangle_height+1) - rest_height, rectangle_width, rectangle_height);
  				}
    		}
    		
    		//show day
    		for(var i = 0; i < 6; i ++)	{
    			if ( seconds / (Math.pow(2,5-i).toLong()) % 2 == 1)	{
    				dc.fillRectangle(2*(rectangle_width+1)-rest_width, (i)*(rectangle_height+1)-rest_height, rectangle_width, rectangle_height-1);
    			}
    		}
        } else {
        	dc.drawText(
            	dc.getWidth() / 2,
            	pwrY,
            	smallFont,
            	pwrString,
            	Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        	);
        
        	dc.drawText(
            	dc.getWidth() / 2,
            	clockY,
           		smallFont,
            	timeString,
            	Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
       	 	);
        
        	dc.drawText(
            	dc.getWidth() / 2,
            	hourY,
            	mainFont,
            	hourString,
            	Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        	);
        
        	dc.drawText(
           		dc.getWidth() / 2,
            	minY,
           		mainFont,
            	minuteString,
            	Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        	);
        
        	dc.drawText(
            	dc.getWidth() / 2,
            	secY,
            	mainFont,
            	secondsString,
            	Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        	);
        
         	dc.drawText(
            	dc.getWidth() / 2,
            	timeSetY,
            	smallFont,
            	countToString,
            	Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        	);
        
        	dc.drawText(
            	dc.getWidth() / 2,
            	finishedY,
            	smallFont,
            	finishedString,
            	Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        	);
        }
        
        
        
        
    }

    public function changeRectangleMode(recMode) {
		if (recMode == true) {
			recMode = false;
		} else {
			recMode = true;
			
		}
		WatchUi.requestUpdate();
		return recMode;
	}
    
    //! If the timer is running, pause it. Otherwise, start it up.
    public function startStopTimer() as Void {
        var now = Time.now().value();

        var timerStartTime = _timerStartTime;
        if (timerStartTime == null) {
            _timerStartTime = now;
            _updateTimer.start(method(:requestUpdate), 1000, true);
        } else {
            var timerPauseTime = _timerPauseTime;
            if (timerPauseTime == null) {
                _timerPauseTime = now;
                _updateTimer.stop();
                WatchUi.requestUpdate();
            } else {
                if ((timerPauseTime - timerStartTime) < _timerDuration) {
                    _timerStartTime = timerStartTime + (now - timerPauseTime);
                    _timerPauseTime = null;
                    _updateTimer.start(method(:requestUpdate), 1000, true);
                }
            }
        }
    }
    
    public function stopTimer() as Void {
	    _updateTimer.stop();
	    WatchUi.requestUpdate();
        
    }
    

    //! If the timer is paused, then go ahead and reset it back to the default time.
    //! @return true if timer is reset, false otherwise
    public function resetTimer() as Boolean {
        if (_timerPauseTime != null) {
            _timerStartTime = null;
            _timerPauseTime = null;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    //! Save all the persisted values into the object store. This gets
    //! called by the Application base before the application shuts down.
    public function saveProperties() as Void {
        Storage.setValue(TIMER_KEY_DURATION, _timerDuration);
        Storage.setValue(TIMER_KEY_START_TIME, _timerStartTime);
        Storage.setValue(TIMER_KEY_PAUSE_TIME, _timerPauseTime);
    }

    //! Set up a background event to occur when the timer expires. This
    //! will alert the user that the timer has expired even if the
    //! application does not remain open.
    public function setBackgroundEvent() as Void {
        var timerStartTime = _timerStartTime;
        if ((timerStartTime != null) && (_timerPauseTime == null)) {
            var time = new Time.Moment(timerStartTime);
            time = time.add(new Time.Duration(_timerDuration));
            try {
                var info = Time.Gregorian.info(time, Time.FORMAT_SHORT);
                Background.registerForTemporalEvent(time);
            } catch (e instanceof Background.InvalidBackgroundTimeException) {
                // We shouldn't get here because our timer is 5 minutes, which
                // matches the minimum background time. If we do get here,
                // then it is not possible to set an event at the time when
                // the timer is going to expire because we ran too recently.
            }
        }
    }

    //! Delete the background event. We can get rid of this event when the
    //! application opens because now we can see exactly when the timer
    //! is going to expire. We will set it again when the application closes.
    public function deleteBackgroundEvent() as Void {
        Background.deleteTemporalEvent();
    }

    //! If we do receive a background event while the application is open,
    //! go ahead and reset to the default timer.
    public function backgroundEvent() as Void {
        _timerDuration = TIMER_DURATION_DEFAULT;
        _timerStartTime = null;
        _timerPauseTime = null;
        WatchUi.requestUpdate();
    }

    //! This is the callback method we use for our timer. It is
    //! only needed to request display updates as the timer counts
    //! down so we see the updated time on the display.
    public function requestUpdate() as Void {
        WatchUi.requestUpdate();
    }
}
