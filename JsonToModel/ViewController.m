//
//  ViewController.m
//  JsonToModel
//
//  Created by 李兆祥 on 2018/4/17.
//  Copyright © 2018年 李兆祥. All rights reserved.
//

#import "ViewController.h"
@interface ViewController()
@property (unsafe_unretained) IBOutlet NSTextView *inputTv;
@property (copy,atomic) NSString *outputStr;
@property (strong,atomic) NSMutableArray *resultArr;
@property (unsafe_unretained) IBOutlet NSTextView *outputTv;
@property (weak) IBOutlet NSButtonCell *noteCheckBtn;
@property (weak) IBOutlet NSButton *noteBtn;
@property (weak) IBOutlet NSButton *dicBtn;
@property (unsafe_unretained) IBOutlet NSTextView *annotationTf;

@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.outputStr = @"";
    self.resultArr = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appReopen) name:@"appReopen" object:nil];
}
#pragma mark json转字典
- (NSDictionary *)getDicWithJsonStr:(NSString *)jsonStr{
    jsonStr = [[[[jsonStr stringByReplacingOccurrencesOfString:@"\n" withString:@""]stringByReplacingOccurrencesOfString:@"\t" withString:@""]stringByReplacingOccurrencesOfString:@" " withString:@""]stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    if(self.dicBtn.state == NSControlStateValueOn){
        jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@";};" withString:@"};"];
        jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@";}" withString:@"}"];
        jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@";" withString:@","];
        jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"=" withString:@":"];
        jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"(" withString:@"["];
        jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@")" withString:@"]"];
        NSString *regex = @"[,{].*?:";
        NSError *error;
        NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:regex
                                                                                 options:NSRegularExpressionCaseInsensitive
                                                                                   error:&error];
        NSArray *matches = [regular matchesInString:jsonStr
                                            options:0
                                              range:NSMakeRange(0, jsonStr.length)];
        NSMutableString* jsonMuStr = [[NSMutableString alloc]initWithString:jsonStr];
        int i = 1;
        for (NSTextCheckingResult *match in matches) {
            NSRange range = [match range];
            NSString *mStr = [jsonStr substringWithRange:range];
            if(![mStr containsString:@"\""]){
                [jsonMuStr insertString:@"\"" atIndex:range.location + i];
                i += 2;
                [jsonMuStr insertString:@"\"" atIndex:range.location + i + range.length - 3];
            }
            
        }
        jsonStr = [self correctErrValueWithJsonStr:jsonMuStr];
    }
    
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                         options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert addButtonWithTitle:@"好"];
        alert.messageText = @"错误";
        alert.informativeText = @"json字符串不合法";
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
            
        }];
        return nil;
    }
    return dic;
    
}
-(NSString *)correctErrValueWithJsonStr:(NSString *)jsonStr{
    NSString *regex = @":.*?,";
    NSError *error;
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:regex
                                                                             options:NSRegularExpressionCaseInsensitive
                                                                               error:&error];
    NSArray *matches = [regular matchesInString:jsonStr
                                        options:0
                                          range:NSMakeRange(0, jsonStr.length)];
    NSMutableString* jsonMuStr = [[NSMutableString alloc]initWithString:jsonStr];
    int i = 1;
    for (NSTextCheckingResult *match in matches) {
        NSRange range = [match range];
        NSString *mStr = [jsonStr substringWithRange:range];
        if(mStr.length > 2)
        mStr = [mStr substringWithRange:NSMakeRange(1, mStr.length - 2)];
        if(![mStr containsString:@"\""] && ![self isPureNumber:mStr] && ![mStr containsString:@"}"] && ![mStr containsString:@"["] && ![mStr containsString:@"true"] && ![mStr containsString:@"false"]){
            [jsonMuStr insertString:@"\"" atIndex:range.location + i];
            i += 2;
            [jsonMuStr insertString:@"\"" atIndex:range.location + i + range.length - 3];
        }
        
    }
    return jsonMuStr;
    
}
- (BOOL)isPureNumber:(NSString*)string{
    return [self isPureInt:string] || [self isPureFloat:string];
}
- (BOOL)isPureInt:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
}

- (BOOL)isPureFloat:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    float val;
    return[scan scanFloat:&val] && [scan isAtEnd];
}
#pragma mark 点击了转换
- (IBAction)convertAction:(id)sender {
    [self.resultArr removeAllObjects];
    NSString *jsonStr = self.inputTv.string;
    if(!jsonStr.length){
        NSAlert *alert = [[NSAlert alloc]init];
        [alert addButtonWithTitle:@"好"];
        alert.messageText = @"错误";
        alert.informativeText = @"请输入需要转换的json字符串";
        [alert setAlertStyle:NSAlertStyleWarning];
        [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
            
        }];
        return;
    }
    NSDictionary *resultDic = [self getDicWithJsonStr:jsonStr];
    [self recursionForResultWithObj:resultDic];
    NSMutableArray *finalResultArr = [NSMutableArray array];
    for (NSArray *subArr in self.resultArr) {
        if(![finalResultArr containsObject:subArr]){
            [finalResultArr addObject:subArr];
        }
    }
    finalResultArr = (NSMutableArray *)[[finalResultArr reverseObjectEnumerator] allObjects];
    NSString *outputStr = @"";
    NSString *annotationStr = self.annotationTf.string;
    NSArray *annArr = [annotationStr componentsSeparatedByString:@"\n"];
    NSMutableArray *resultArr = [NSMutableArray array];
    NSMutableDictionary *annDic = [NSMutableDictionary dictionary];
    NSMutableArray *indexArr = [NSMutableArray array];
    int i = 0;
    for (NSString *annSubStr in annArr) {
        if(annSubStr.length){
            if([self pureLetters:annSubStr] && ![annSubStr isEqualToString:@"array"] && ![annSubStr isEqualToString:@"string"]){
                //如果是纯英文或者_
                [indexArr addObject:[NSNumber numberWithInt:i]];
            }
            i++;
            [resultArr addObject:annSubStr];
        }
        
    }
    for (int i = 0 ;i < indexArr.count;i++) {
        NSNumber *n = indexArr[i];
        NSString *key = resultArr[[n integerValue]];
        NSString *value;
        if(i + 1 < indexArr.count){
            value = resultArr[[indexArr[i + 1] integerValue] - 1];
        }else{
            value = resultArr[resultArr.count - 1];
        }
        if(value)
        annDic[key] = value;
        
    }
    for (NSArray *subArr in finalResultArr) {
        outputStr = [outputStr stringByAppendingString:@"------------------------------\n"];
        for (NSString *str in subArr) {
            NSString * str2;
            if(self.noteBtn.state == NSControlStateValueOn){
                NSString *annStr = @"";
                for (NSString *key in annDic.allKeys) {
                    NSLog(@"%@--%@",[str componentsSeparatedByString:@" *"][1],annDic[key]);
                    if([str componentsSeparatedByString:@" *"].count > 1 && [[str componentsSeparatedByString:@" *"][1]isEqualToString:[key stringByAppendingString:@";\n"]] && annDic[key]){
                        annStr = annDic[key];
                    }
                }
               str2 = [NSString stringWithFormat:@"///%@\n%@",annStr,str];
            }else{
               str2 = str;
            }
            outputStr = [outputStr stringByAppendingString:str2];
        }
    }
    self.outputTv.string = outputStr;
}
#pragma mark 递归解析
-(void)recursionForResultWithObj:(id)obj{
    if([obj isKindOfClass:[NSArray class]]){
        for (id subObj in obj) {
            [self recursionForResultWithObj:subObj];
        }
    }else if([obj isKindOfClass:[NSDictionary class]]){
        NSMutableArray *tempArr = [NSMutableArray array];
        for (NSString *key in [self getKeyNamesWithDic:obj]){
            id value = [obj objectForKey:key];
            if([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]){
                [tempArr addObject:[NSString stringWithFormat:@"@property (nonatomic, strong) %@ *%@;\n",[[value superclass] class],key]];
                
                [self recursionForResultWithObj:value];
            }else{
                if([value isKindOfClass:[NSString class]]){
                    
                    [tempArr addObject:[NSString stringWithFormat:@"@property (nonatomic, copy) %@ *%@;\n",[NSString class],key]];
                }else if([value isKindOfClass:[NSNumber class]]){
                    [tempArr addObject:[NSString stringWithFormat:@"@property (nonatomic, strong) %@ *%@;\n",[NSNumber class],key]];
                }else{
                    [tempArr addObject:[NSString stringWithFormat:@"@property (nonatomic, strong) %@ *%@;\n",@"id",key]];
                }
            }
            [self.resultArr addObject:tempArr];
        }
        
        
    }
}
-(BOOL)pureLetters:(NSString*)str{
    
    for(int i=0;i < str.length;i++){
        
        unichar c = [str characterAtIndex:i];
        
        if((c < 'A'|| c > 'Z')&&(c < 'a'||c > 'z') && c != '_' )
            return NO;
    }
    
    return YES;
    
}
#pragma mark 获取字典中所有排序好的key（因为字典是无序的）
- (NSArray *)getKeyNamesWithDic:(NSDictionary *)dic{
    NSArray *sortedArray = [dic.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1,id obj2) {
        return[obj1 compare:obj2 options:NSNumericSearch];
    }];
    return sortedArray;
}
-(void)appReopen{
    [NSApp activateIgnoringOtherApps:NO];
    [self.view.window makeKeyAndOrderFront:self];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
