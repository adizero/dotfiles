function main()
	options.certificates = false

    local account = IMAP {
        -- server = 'mail.eu.alcatel-lucent.com',
        -- username = 'akocis',
        -- password = get_imap_password(".microsoft_imap_app_password"),
        server = 'outlook.office365.com',
        username = 'adrian.kocis@nokia.com',
		password = get_imap_password(".microsoft_imap_app_password"),
		port = 993,
        ssl = 'tls1',
    }

    -- Make sure the account is configured properly
    ----account:list_all("Antwerp")
    --account.Inbox:check_status()
    -- account['[Gmail]/Trash']:check_status()
    -- account['[Gmail]/Spam']:check_status()

	-- mailboxes, folders = account:list_all ('*')
	-- for i,m in pairs (mailboxes) do
	--    -- account[m]:check_status ()
	--    messages = account[m]:is_unseen () -- + account[m]:is_new ()
	--    subjects = account[m]:fetch_fields ({ 'subject' }, messages)
	--    if subjects ~= nil then
	-- 	  print (i)
	-- 	  print (m)
	-- 	  for j,s in pairs (subjects) do
	-- 		 print (string.format ("t%s", string.sub (s, 0, s:len () - 1)))
	-- 	  end
	--    end
	-- end
	
	mailboxes, folders = account:list_all ()

	for i,t in pairs (folders) do
		print (string.format("--folder %d %s", i, t))
		mailboxes2, folders2 = account:list_all (t)
		for i,m in pairs (mailboxes2) do
			--print (string.format("", folder))
			account[m]:check_status ()
		end
	end

	print (string.format("--no folder"))
	for i,m in pairs (mailboxes) do
		--print (string.format("", folder))
		account[m]:check_status ()
	--    messages = account[m]:is_unseen () -- + account[m]:is_new ()
	--    subjects = account[m]:fetch_fields ({ 'subject' }, messages)
--    if subjects ~= nil then
	-- 	  print (i)
	-- 	  print (m)
	-- 	  for j,s in pairs (subjects) do
	-- 		 print (string.format ("t%s", string.sub (s, 0, s:len () - 1)))
	-- 	  end
	--    end
	end

	
-- 	mails = account.INBOX:select_all() + account["Junk E-mail"]:select_all()
-- 
-- 	mails = mails:is_newer(1)
-- 
-- --	tos = account.INBOX:fetch_fields ({ 'cc' }, mails)
-- --	if tos ~= nil then
-- --		for j,s in pairs (tos) do
-- --			print (string.format ("%s", string.sub (s, 0, s:len () - 1)))
-- --		end
-- --	end
-- 
-- 	--filtered = mails:match_subject("^REGRESS:") + mails:match_subject("^SITE:")  -- costs 3 minutes of downloading headers for the whole 1000 msgs INBOX
-- 	filtered = mails:contain_subject("REGRESS:") + mails:contain_subject("SITE:")
-- 	filtered:move_messages(account["Antwerp/REGRESS"])
-- 	mails = mails - filtered
-- 
-- 	--filtered = mails:contain_to("7750.Interest@alcatel-lucent.com") + mails:contain_to("7750.interest@mailman.usa.alcatel.com") +
-- 	--	mails:contain_cc("7750.Interest@alcatel-lucent.com") + mails:contain_cc("7750.interest@mailman.usa.alcatel.com")
-- 	--INTEREST 7750 <7750.Interest@alcatel-lucent.com>
-- 	filtered = mails:contain_to("7750") + mails:contain_cc("7750")
-- 	filtered:move_messages(account["Antwerp/7750.Interest"])
-- 	mails = mails - filtered
-- 	
-- 	-- filtered = mails:contain_to("7450-antwerp@LIST.ALCATEL-LUCENT.COM") + mails:contain_to("sros-antwerp@LIST.ALCATEL-LUCENT.COM")
-- 	-- filtered:move_messages(account["Antwerp/7450-antwerp"])
-- 	-- mails = mails - filtered
-- 	
-- 	filtered = mails:contain_subject("SR environment") + mails:contain_from("cron daemon")
-- 	filtered:move_messages(account["Antwerp/SR environment"])
-- 	mails = mails - filtered
-- 	
-- 	--filtered = mails:contain_to("sw-timetra@LIST.ALCATEL-LUCENT.COM") + mails:contain_cc("sw-timetra@LIST.ALCATEL-LUCENT.COM")
-- 	--SW-TIMETRA <sw-timetra@LIST.ALCATEL-LUCENT.COM>
-- 	filtered = mails:contain_to("sw-timetra") + mails:contain_cc("sw-timetra")
-- 	filtered:move_messages(account["Antwerp/SW-TIMETRA"])
-- 	mails = mails - filtered
-- 	
-- 	--filtered = mails:contain_to("sr-linux-ug@LIST.ALCATEL-LUCENT.COM") + mails:contain_cc("sr-linux-ug@LIST.ALCATEL-LUCENT.COM")
-- 	filtered = mails:contain_to("sr-linux-ug") + mails:contain_cc("sr-linux-ug")
-- 	filtered:move_messages(account["Antwerp/SR linux users"])
-- 	mails = mails - filtered
-- 
-- 	--filtered = mails:contain_to("9471-wmm-interest@list.alcatel-lucent.com") + mails:contain_cc("9471-wmm-interest@list.alcatel-lucent.com")
-- 	filtered = mails:contain_to("9471-wmm-interest") + mails:contain_cc("9471-wmm-interest")
-- 	filtered:move_messages(account["WMM interest"])
-- 	mails = mails - filtered
-- 
-- 	--filtered = mails:contain_from("no-reply.engage@alcatel-lucent.com")
-- 	filtered = mails:contain_from("engage")
-- 	filtered:move_messages(account["Newsletters"])
-- 	mails = mails - filtered
-- 
-- 	filtered = mails:contain_subject("interview") + mails:contain_subject("SW development engineer")
-- 	filtered:move_messages(account["Interview"])
-- 	mails = mails - filtered
-- 
-- 	-- filtered = mails:contain_to("adrian.kocis@alcatel-lucent.sk") + mails:contain_cc("adrian.kocis@alcatel-lucent.sk") +
-- 	-- 	mails:contain_from("adrian.kocis@alcatel-lucent.sk") + 
-- 	-- 	mails:contain_to("a.csadi@alcatel-lucent.sk") + mails:contain_cc("a.csadi@alcatel-lucent.sk")
-- 	-- filtered:move_messages(account["Junk"])
-- 	-- mails = mails - filtered
-- 
-- 	filtered = mails:contain_subject("SPAM") + mails:contain_from("Hilton HHonors") + mails:contain_from("Hilton Garden Inn") + mails:contain_from("Chad Kulpa")
-- 	filtered:move_messages(account["Junk E-mail"])
-- 	mails = mails - filtered
-- 
-- 	-- send the rest back to the INBOX
-- 	mails:move_messages(account["INBOX"])
-- 
-- 
-- 
-- 
-- 	--for i,s in pairs (filtered) do
-- 	--	print (s)
-- 	--end
-- 
--     -- -- Get all mail from INBOX
--     -- mails = account.INBOX:select_all()
-- 
--     -- -- Move mailing lists from INBOX to correct folders
--     -- move_mailing_lists(account, mails)
-- 
--     -- -- Delete some trash
--     -- delete_mail_from(account, mails, "enews@rockabilia.com");
--     -- delete_mail_from(account, mails, "updates@comms.packtpub.com");
--     -- delete_mail_from(account, mails, "vaultlist@enterthevault.com");
--     -- delete_mail_from(account, mails, "Inneke.Berghmans@PPW.KULEUVEN.BE");
-- 
--     -- delete_mail_if_subject_contains(account, mails, "[CSSeminars] ");
-- 
--     -- -- Get all mail from trash
--     -- mails = account['[Gmail]/Trash']:select_all()
-- 
--     -- -- Move mailing lists from trash to correct folders
--     -- move_mailing_lists(account, mails)
-- 
--     -- -- Get all mail from spam
--     -- mails = account['[Gmail]/Spam']:select_all()
-- 
--     -- -- Move mailing lists from spam to correct folders
--     -- move_mailing_lists(account, mails)
-- 
--     -- move_if_from_contains(account, mails, "edarling.ch", "INBOX")
--
--     account1:create_mailbox('Spam')

    filter_mails(account, "Junk E-mail")
    filter_mails(account, "INBOX")
    
    -- mails = account["Calendar"]:select_all()
	-- for _, mesg in ipairs(mails) do
		-- print(mesg)
		-- mbox, uid = table.unpack(mesg)
		-- print(uid)
		-- text = mbox[uid]:fetch_message()
		-- print(text)
		-- if text ~= nil then
			-- pipe_to('cat', text)
		-- end
		-- -- if (pipe_to('bayesian-spam-filter', text) == 1) then
		-- -- 	table.insert(results, mesg)
		-- -- end
	-- end
end

function filter_mails(account, folder)
    mails = account[folder]:select_all()
	mails = mails:is_newer(4)  -- select only mails less than X days old

	tos = account.INBOX:fetch_fields ({ 'to', 'cc' }, mails)
	if tos ~= nil then
		for j,s in pairs (tos) do
			print (string.format ("%s", string.sub (s, 0, s:len () - 1)))
		end
	end

	--filtered = mails:match_subject("^REGRESS:") + mails:match_subject("^SITE:")  -- costs 3 minutes of downloading headers for the whole 1000 msgs INBOX
	filtered = mails:contain_subject("REGRESS:") + mails:contain_subject("SITE:")
	filtered:move_messages(account["Antwerp/REGRESS"])
	mails = mails - filtered

	filtered = mails:contain_subject("SR env") + mails:contain_from("cron daemon")
	filtered:move_messages(account["Antwerp/SR environment"])
	mails = mails - filtered
	
    filtered = mails:match_to("sr-sw-bra") + mails:match_cc("sr-sw-bra")
    filtered:move_messages(account["Main"])  --TODO AKO improve (do not go directly to Main as this skips SPAM filtering)
    mails = mails - filtered

	--filtered = mails:contain_to("sw-timetra@LIST.ALCATEL-LUCENT.COM") + mails:contain_cc("sw-timetra@LIST.ALCATEL-LUCENT.COM")
	--SW-TIMETRA <sw-timetra@LIST.ALCATEL-LUCENT.COM>
	---filtered = mails:contain_to("sw-timetra") + mails:contain_cc("sw-timetra")
	filtered = mails:match_to("sr-sw") + mails:match_cc("sr-sw") + mails:match_to("sw-timetra") + mails:match_cc("sw-timetra")
	filtered:move_messages(account["Antwerp/SW-TIMETRA"])
	mails = mails - filtered
	
	--filtered = mails:contain_to("sr-linux-ug@LIST.ALCATEL-LUCENT.COM") + mails:contain_cc("sr-linux-ug@LIST.ALCATEL-LUCENT.COM")
	---filtered = mails:contain_to("sr-linux-ug") + mails:contain_cc("sr-linux-ug")
	filtered = mails:match_to("sr-linux-ug") + mails:match_cc("sr-linux-ug")
	filtered:move_messages(account["Antwerp/SR linux users"])
	mails = mails - filtered

	--filtered = mails:contain_to("7750.Interest@alcatel-lucent.com") + mails:contain_to("7750.interest@mailman.usa.alcatel.com") +
	--	mails:contain_cc("7750.Interest@alcatel-lucent.com") + mails:contain_cc("7750.interest@mailman.usa.alcatel.com")
	--INTEREST 7750 <7750.Interest@alcatel-lucent.com>
	---filtered = mails:contain_to("7750") + mails:contain_cc("7750")
	-----filtered = mails:match_to("7750") + mails:match_cc("7750")
	filtered = mails:match_to("iprouting-interest") + mails:match_cc("iprouting-interest") + mails:match_to("7750") + mails:match_cc("7750")
	filtered:move_messages(account["Antwerp/7750.Interest"])
	mails = mails - filtered
	
	-- filtered = mails:contain_to("7450-antwerp@LIST.ALCATEL-LUCENT.COM") + mails:contain_to("sros-antwerp@LIST.ALCATEL-LUCENT.COM")
	-- filtered:move_messages(account["Antwerp/7450-antwerp"])
	-- mails = mails - filtered
	
	--filtered = mails:contain_to("9471-wmm-interest@list.alcatel-lucent.com") + mails:contain_cc("9471-wmm-interest@list.alcatel-lucent.com")
	---filtered = mails:contain_to("9471-wmm-interest") + mails:contain_cc("9471-wmm-interest")
	filtered = mails:match_to("9471-wmm-interest") + mails:match_cc("9471-wmm-interest") + mails:match_to("cmm-interest") + mails:match_cc("cmm-interest")
	filtered:move_messages(account["WMM interest"])
	mails = mails - filtered

	--filtered = mails:contain_from("no-reply.engage@alcatel-lucent.com")
	filtered = mails:contain_from("engage")
	filtered:move_messages(account["Newsletters"])
	mails = mails - filtered

    filtered = mails:contain_from("bugmeister")
    filtered:move_messages(account["Bugmeister"])
    mails = mails - filtered

    filtered = mails:contain_subject("[sr-srlinux] Automerge report for ")
    filtered:move_messages(account["Builds"])
    mails = mails - filtered

	filtered = mails:contain_from("Build Meister")
	filtered:move_messages(account["Buildmeister"])
	mails = mails - filtered

	filtered = mails:contain_subject("srlinux Yang Change Notifier") + mails:contain_subject("[Action Required] Summary of diff between planned vs working yang files")
	filtered:move_messages(account["Unfiltered"])
	mails = mails - filtered

	filtered = mails:contain_subject("interview") + mails:contain_subject("SW development engineer")
	filtered:move_messages(account["Interview"])
	mails = mails - filtered

	-- filtered = mails:contain_to("adrian.kocis@alcatel-lucent.sk") + mails:contain_cc("adrian.kocis@alcatel-lucent.sk") +
	-- 	mails:contain_from("adrian.kocis@alcatel-lucent.sk") + 
	-- 	mails:contain_to("a.csadi@alcatel-lucent.sk") + mails:contain_cc("a.csadi@alcatel-lucent.sk")
	-- filtered:move_messages(account["Junk"])
	-- mails = mails - filtered

    -- folder dependent filters
    filtered = mails:contain_subject("SPAM") + mails:contain_from("Hilton HHonors") + mails:contain_from("Hilton Garden Inn") + mails:contain_from("Chad Kulpa")    
    if folder == "INBOX" then
        -- send spam to Junk E-mail
        filtered:move_messages(account["Junk E-mail"])
    end
    mails = mails - filtered

    if (folder == "Junk E-mail") then
        -- send the rest back to the INBOX
        mails:move_messages(account["INBOX"])
    end

    if folder == "INBOX" then
        -- filter rest of the mails with SpamAssassin 3.4.1
        -- hams will go to Main IMAP folder
        -- spams will go to Spam IMAP folder
        hams = Set {}
        spams = Set {}
        for _, mesg in ipairs(mails) do
            -- print("HEEEEEEEEREEEE")
            -- print(mesg)
            mbox, uid = table.unpack(mesg)
            -- print(uid)
            text = mbox[uid]:fetch_message()
            -- print(text)
            -- header = mbox[uid]:fetch_header()
            -- print(header)
            -- body = mbox[uid]:fetch_body()
            -- print(body)
            if text ~= nil then
                -- pipe_to('cat > /tmp/_sa_input', text)
                local spam
                if (pipe_to('spamassassin -e 1>/dev/null', text) == 0) then
                    spam = 0
                else
                    spam = 1
                end

                if spam == 0 then
                    print ("HAM")
                    table.insert(hams, mesg)
                else
                    print("SPAM")
                    table.insert(spams, mesg)
                end
            end
        end
        
        --- -- send real post-filtered INBOX messages to Main folder
        --- mails:move_messages(account["Main"])
        hams:move_messages(account["Main"])
        spams:move_messages(account["Spam"])
    end
end

-- Utility function to get IMAP password from file
function get_imap_password(file)
    local home = os.getenv("HOME")
    local file = home .. "/" .. file
    local str = io.open(file):read()
    return str;
end

main() -- Call the main function
