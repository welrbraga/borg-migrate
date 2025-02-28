# Borg migrate

This tool allow us to migrate just some backups from a Borg repository to another.

It solve the problem of starts to do backups in a midia and because the growing volume, you need to delete some backups, or migrate everything to new bigger midia.

With borg-migrate you just migrate some backups to another repository in another disk with more free space.

## How it works

After save the informations of both repositories (source and target) and knowing the name of the backup you will move, just invoke borg-migrate with the name of the backup in the source repo.

The existence of the source and target repo path, passwords and source backup will be checked and if it is ok, we get the original date/time when the backup routine started on the source repo.

Passed these checks, the borg import-tar and borg export-tar will do the work in a pipeline to read from one repo and transfer it to another one.

If the transfer is concluded with sucess, the original backup in source repo is imediately removed.

## Requirements

This tool, actually is just a shell script that invoke borg executable and some terminal tools like faketime and jq.

* borg 1.4 is the responsable for backups and migrations
* faketime is responsable for preserve the original date/time when create the backup on the target repository
* jq is responsable for take care of some information acquived in JSON format.

Talking about your environment we have these others requirements:

* Ubuntu/Debian box - Sorry guy I have not tested on others distros, Mac OS, BSD etc, so I can't give you guaranty that it will work, but if you try, let me know if it works.
* Two accessible borg repositories - It's expected that both repositories exists and you can access them from the machine where borg-migrate will run.
* BORG_PASSCOMMAND - It's is safer than type your password everytime, or use another method - read bellow
* Portuguese - Is in everywhere. Another sorry (maybe temporary, I expect). I have lots of scripts for my exclusive use and I used to create them and comment them in Portuguese. Borg-migrate was not different, but if it is demmanded I (or maybe we) can translate it.

## Limitations

Because I have used import-tar|export-tar borg commands, the metadata that we can migrate are restricted to that allowed by these commands.

According to Borg 1.4.0 docs, these are the acutal limitations:

    import-tar (and export-tar) is a lossy conversion:
    BSD flags, ACLs, extended attributes (xattrs), atime and ctime are not exported.
    Timestamp resolution is limited to whole seconds, not the nanosecond resolution
    otherwise supported by Borg.
    [...]
    import-tar reads POSIX.1-1988 (ustar), POSIX.1-2001 (pax), GNU tar, UNIX V7 tar
    and SunOS tar with extended attributes.

## Borg password

I know borg can ask you for your password, get it directly in BORG_PASSPHRASE envvar or in open plain file with BORG_PASSPHRASE_FD, but I considered none of these safe enough.

Save your repo password in a file is safer than others methods. Of course, if you this using the right tools.

Bellow I suggest you three examples, where the firsts are less safe than the nexts.

You can put your in a unencrypt file with 0600 permission read just for your own, in reality I use it just in repo tests, never for production.

    ```shell
    BORG_PASSCOMMAND="cat file-with-your-pass"
    ```

A better and safer way, is you hash your password with base64 (for example) and this hash in a file that will be unhashed by the command you inform here. Remember that your password is not encrypted, but it is more secure than save in a plain file.

    ```shell
    BORG_PASSCOMMAND="base64 -d file-with-your-pass"
    ```

Personally I put all my secrets in a vault like Bitwarden and access them safely with one long and secure password and MFA, so I recommend you do the same. Of course there are any others alternatives you can use (Keepass, Lastpass, a encrypted GPG file etc). Be creative, but never relax with your password security.

    ```shell
    BORG_PASSCOMMAND="bw get password 4df5d8d8-d8ce-44fe-a19a-af2401c5623f"
    ```

## Installing

To install the borg-migrate tool, follow these steps:

1. Get a version of the main script borg-migrate.sh. (Tip: Normally, it's nice to remove the extension - "borg-migrate" instead of "borg-migrate.sh")
2. Change your permission to allow your users to run it
3. Move it in some cool folder registered in your PATH like /usr/local/bin, ~/bin, ~/.local/bin and so on
4. That is it

In two commands:

    ```shell
    curl -L https://raw.githubusercontent.com/welrbraga/borg-migrate/refs/heads/main/borg_migrate.sh -o borg-migrate
    sudo install --mode=0755 borg-migrate /usr/local/bin/
    ```

## Configure your repo info

The repo access informations are configured in a file called ".borg-migrate.env" that is expected to be in your $HOME or in the actual directory.

If both exists the version in actual directory will overcharge the $HOME version. YUour content is four variables. Two for each repository:

BORG_REPO - The path of the repo
BORG_PASSCOMMAND - The command that return your repo password

When you run the borg-migrate the first time it will create a sample file called borg-migrate.env.sample to you.

Change your content as you need and rename it to .borg-migrate.env (a dot file, without ".sample" suffix).

## Checking if it is working

After you have configured both repo informations, a good way to check is getting info from them.

    ```shell
    borg-migrate source info
    borg-migrate target info
    ```

Those comands just invoke "borg info" on source repo and on target repo, using the right paths and credentials. If they worked, congratulations. The tool is well configured.

## Migrating a backup

You have instaled the borg-migrat to get here, right? Let's say you have two borg repo configured. To migrate a backup called 'mynotebook-2024-10-03' from one to another, just run in CLI:

    ```shell
    borg-migrate mynotebook-2024-10-03
    ```

Now, get a cup of coffee or tea or juice ... anyway ... wait the end of migration.

How long it will take? It will depend of many factors, like number of files, speed of both midias, number of duplicated files etc. But in my use and tests it is used to take aproximately the same time it took to create the original backup.

## Samples of generic use

You can do more with borg-migrate. Sometimes it is need to run borg commands in one or both repos. Instead of run borg individually and need to redefine variablesor use a long command line, use borg migrate to it.

Like in others samples, you can run any borg command individually for boot repo, let's see some examples.

    ```shell
    # Compacting the source repo after many migrations
    borg-migrate source compact
    ```

    ```shell
    # List backups on the target repo
    borg-migrate target list --glob 'mynotebook*'
    ```

The gold tip is change "borg" command for "borg-migrate source" and "borg-migrate target" and arguments are those you well-known from "borg --help".
