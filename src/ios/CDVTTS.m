/*
    Cordova Text-to-Speech Plugin
    https://github.com/vilic/cordova-plugin-tts
 
    by VILIC VANE
    https://github.com/vilic
 
    MIT License
*/

#import <Cordova/CDV.h>
#import <Cordova/CDVAvailability.h>
#import "CDVTTS.h"

@implementation CDVTTS

- (void)pluginInitialize {
    synthesizer = [AVSpeechSynthesizer new];
    synthesizer.delegate = self;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance*)utterance {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    if (lastCallbackId) {
        [self.commandDelegate sendPluginResult:result callbackId:lastCallbackId];
        lastCallbackId = nil;
    } else {
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        callbackId = nil;
    }
    
    [[AVAudioSession sharedInstance] setActive:NO withOptions:0 error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient 
      withOptions: 0 error: nil];
    [[AVAudioSession sharedInstance] setActive:YES withOptions: 0 error:nil];
}

- (void)speak:(CDVInvokedUrlCommand*)command {
    
    NSDictionary* options = [command.arguments objectAtIndex:0];
    
    NSString* text = [options objectForKey:@"text"];
    // setting id trumps locale setting
    NSString* locale = [options objectForKey:@"locale"];
    NSString* ident = [options objectForKey:@"id"];

    double rate = [[options objectForKey:@"rate"] doubleValue];
    NSString* category = [options objectForKey:@"category"];
    
    [[AVAudioSession sharedInstance] setActive:NO withOptions:0 error:nil];
    if ([category isEqualToString:@"ambient"]) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient
                                         withOptions:0 error:nil];
    } else {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                         withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    }

    if (callbackId) {
        lastCallbackId = callbackId;
    }
    
    callbackId = command.callbackId;
    
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    
    NSDictionary* options = [command.arguments objectAtIndex:0];
    
    NSString* text = [options objectForKey:@"text"];
    NSString* locale = [options objectForKey:@"locale"];
    double rate = [[options objectForKey:@"rate"] doubleValue];
    double pitch = [[options objectForKey:@"pitch"] doubleValue];
    
    if (!locale || (id)locale == [NSNull null]) {
        locale = @"en-US";
    }
    
    if (!rate) {
        rate = 1.0;
    }
    
    if (!pitch) {
        pitch = 1.2;
    }
    
    AVSpeechUtterance* utterance = [[AVSpeechUtterance new] initWithString:text];
    if(ident) {
        utterance.voice = [AVSpeechSynthesisVoice voiceWithIdentifier:ident];
    } else {
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:locale];
    }
    // Rate expression adjusted manually for a closer match to other platform.
    utterance.rate = (AVSpeechUtteranceMinimumSpeechRate * 1.5 + AVSpeechUtteranceDefaultSpeechRate) / 2.25 * rate * rate;
    // workaround for https://github.com/vilic/cordova-plugin-tts/issues/21
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
       utterance.rate = utterance.rate * 2;
       // see http://stackoverflow.com/questions/26097725/avspeechuterrance-speed-in-ios-8
    }
    utterance.pitchMultiplier = pitch;
    [synthesizer speakUtterance:utterance];
}

- (void)stop:(CDVInvokedUrlCommand*)command {
    [synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

- (void)checkLanguage:(CDVInvokedUrlCommand *)command {
    NSArray *voices = [AVSpeechSynthesisVoice speechVoices];
    NSString *languages = @"";
    // Now returns both language code and voice id (which, incidentally, matches speechSynthesis.getVoices()[idx].voiceURI
    // separated by a colon
    for (id voiceName in voices) {
        languages = [languages stringByAppendingString:@","];
        languages = [languages stringByAppendingString:[voiceName valueForKey:@"language"]];
        languages = [languages stringByAppendingString:@":"];
        languages = [languages stringByAppendingString:[voiceName valueForKey:@"identifier"]];
    }
    if ([languages hasPrefix:@","] && [languages length] > 1) {
        languages = [languages substringFromIndex:1];
    }

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:languages];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}
@end
