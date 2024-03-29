window.addEvent('domready', function(){ Ready(); });

function Ready()
{
    //Client.ready();
    //alert("hui");
}

function GetMovie(movieName)
{
    if (navigator.appName.indexOf("Microsoft") != -1)
    {
        return window[movieName];
    }
    else
    {
        return document[movieName];
    }
}


function SafeClientCall()
{
    var clientFunc = arguments[0];
    var args = [];
    for (var i = 1; i < arguments.length; i++)
    {
        if (arguments[i] === undefined)
        {
            //Do nothing...
        }
        else if (arguments[i].constructor == String)
        {
            if (arguments[i].length > 15)
            {
                args.push('&START_STRING*');
                var strLen = arguments[i].length;
                var currentPos = 0;
                while (currentPos < strLen)
                {
                    var currentStr = arguments[i].substr(currentPos, 15);
                    args.push(currentStr);
                    currentPos += 15;
                }
                args.push('&END_STRING*');
            }
            else
            {
                args.push(arguments[i]);
            }
        }
        else
        {
            args.push(arguments[i]);
        }
    }

    var evalStr = 'Client.' + clientFunc + "(";
    for (var i = 0; i < args.length; i++)
    {
        if (i != 0)
        {
            evalStr += ", ";
        }

        if (args[i].constructor == String)
        {
            evalStr += '"' + args[i] + '"';
        }
        else
        {
            evalStr += args[i].toString();
        }
    }
    evalStr += ");";
    eval(evalStr)
}