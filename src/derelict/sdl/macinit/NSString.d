/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/
module derelict.sdl.macinit.NSString;

version(DigitalMars) version(OSX) version = darwin;

version (darwin):

version (Tango)
{
    import tango.text.convert.Utf : toString16;
    import tango.stdc.stringz : toString16z;
}

else
    import std.utf : toUTF16z;

import derelict.sdl.macinit.ID;
import derelict.sdl.macinit.NSGeometry;
import derelict.sdl.macinit.NSObject;
import derelict.sdl.macinit.NSZone;
import derelict.sdl.macinit.runtime;
import derelict.sdl.macinit.selectors;
import derelict.sdl.macinit.string;
import derelict.util.compat;

package:

class NSString : NSObject
{
    this ()
    {
        id_ = null;
    }

    this (id id_)
    {
        this.id_ = id_;
    }

    static NSString alloc ()
    {
        id result = objc_msgSend(cast(id)class_, sel_alloc);
        return result ? new NSString(result) : null;
    }

    static Class class_ ()
    {
        return cast(Class) objc_getClass!(this.stringof);
    }

    override NSString init ()
    {
        id result = objc_msgSend(this.id_, sel_init);
        return result ? this : null;
    }

    static NSString stringWith (string str)
    {
        version (Tango)
            id result = objc_msgSend(class_NSString, sel_stringWithCharacters_length, toString16z(str.toString16()), str.length);

        else
            id result = objc_msgSend(class_NSString, sel_stringWithCharacters_length, str.toUTF16z(), str.length);

        return result !is null ? new NSString(result) : null;
    }

    static NSString opAssign (string str)
    {
        return stringWith(str);
    }

    NSUInteger length ()
    {
        return cast(NSUInteger) objc_msgSend(this.id_, sel_length);
    }

    /*const*/ char* UTF8String ()
    {
        return cast(/*const*/ char*) objc_msgSend(this.id_, sel_UTF8String);
    }

    void getCharacters (wchar* buffer, NSRange range)
    {
        objc_msgSend(this.id_, sel_getCharacters_range, buffer, range);
    }

    NSString stringWithCharacters (/*const*/ wchar* chars, NSUInteger length)
    {
        id result = objc_msgSend(this.id_, sel_stringWithCharacters_length, chars, length);
        return result ? new NSString(result) : null;
    }

    NSRange rangeOfString (NSString aString)
    {
        return *cast(NSRange*) objc_msgSend(this.id_, sel_rangeOfString, aString ? aString.id_ : null);
    }

    NSString stringByAppendingString (NSString aString)
    {
        id result = objc_msgSend(this.id_, sel_stringByAppendingString, aString ? aString.id_ : null);
        return result ? new NSString(result) : null;
    }

    NSString stringByReplacingRange (NSRange aRange, NSString str)
    {
        size_t bufferSize;
        size_t selfLen = this.length;
        size_t aStringLen = str.length;
        wchar* buffer;
        NSRange localRange;
        NSString result;

        bufferSize = selfLen + aStringLen - aRange.length;
        buffer = cast(wchar*) NSAllocateMemoryPages(bufferSize * wchar.sizeof);

        /* Get first part into buffer */
        localRange.location = 0;
        localRange.length = aRange.location;
        this.getCharacters(buffer, localRange);

        /* Get middle part into buffer */
        localRange.location = 0;
        localRange.length = aStringLen;
        str.getCharacters(buffer + aRange.location, localRange);

        /* Get last part into buffer */
        localRange.location = aRange.location + aRange.length;
        localRange.length = selfLen - localRange.location;
        this.getCharacters(buffer + aRange.location + aStringLen, localRange);

        /* Build output string */
        result = NSString.stringWithCharacters(buffer, bufferSize);

        NSDeallocateMemoryPages(buffer, bufferSize);

        return result;
    }
}
