# Borg migrate

This tool allow us to migrate just some backups from a Borg repository to another.

It solve the problem of starts to do backups in a midia and because its volume increases you need to delete them, or migrate everything to new bigger midia.

For example I keep all my borg backups in a USB drive with 1TB, for 3 or 4 years, but last week it ran out of space. Without borg-migrate I need to delete some backups, or migrate all my repo to a new disk with more free space.

With borg-migrate I just migrate some backups to another repositorie in a disk with more free space.

## How it works

After save the informations of both repositories (source and target) you can invoque this tool informing only the name of the backup in the source repo.

The existence of the source repo, target repo and source backup will be checked and if it is ok, we get the original date/time when the backup routine started on the source repo.

Passed these checks, the borg import-tar and borg export-tar are invocked in a pipeline to read from one repo and transfer it to another one.

If the transfer is concluded with sucess, the original backup in source repo is imediately removed.

## Requirements

This tool, actually is justa a shell script that invoke borg executable and some terminal tools like faketime and jq.

* borg 1.4 is the responsable for backups and migrations
* faketime is responsable for preserve the original date/time when create the backup on the target repository
* jq is responsable for take care of some information acquived in JSON format.

Talking about env we have these others requirements:

* Linux box - Sorry guy I have not tested on Mac OS, BSD etc, so I can't give you guaranty that it will work, but if you try, let me know if it works.
* Two accessible borg repositories - It's expected that both repositories exists and you can access them from the machine where borg-migrate will run.
* Portuguese - Is in everywhere. Another sorry (maybe temporary, I expect). I have lots of scripts for my exclusive use and I used to create them in portuguese Borg-migrate was not different but it has demand I or (maybe) we can translate it.

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

## Installing

To install just follow these steps:

1. Get a version of the main script (borg-migrate.sh) and save it in some cool folder registered in your PATH, like /usr/local/bin, ~/.bin, ~/.local/bin and so on. (Tip: Normally, it's nice to remove the extension - borg-migrate, instead of borg-migrate.sh)
2. Change your permission to allow your users to run it (chmod a+x ~/usr/local/bin/borg-migrate)
3. Configure your repo informations in a file called ~/.borg-migrate.env

## Checking

If you have configured both repo infomrations you can access them.

A good way to check is getting info from them.

    ```shell
    borg-migrate source info
    borg-migrate target info
    ```

Those comands just invoke "borg info" on source repo and on target repo, using the right paths and credentials. If they worked, congratulations. The tool is well configured.

## Migrating a backup

Let's say I have two borg repo configured, and I need to migrate a backup called 'mynotebook-2024-10-03' from one to another. I just run in CLI:

    ```shell
    borg-migrate mynotebook-2024-10-03
    ```

Now, get a cup of cofee or tea or juice ... anyway ... wait the end of migration.

How long it will take? It will depend of many factors, like number of files, speed of both midias, number of duplicated files etc. But in my use and tests it is used to take aproximately the same time it took to create the original backup.

## Samples of generic use

Like in those examples, you can run any borg command individually for boot repo, let's see some examples.

    ```shell
    # Compacting the source repo after many migrations
    borg-migrate source compact
    ```

    ```shell
    # List backups on the target repo
    borg-migrate target list --glob 'mynotebook*'
    ```

Note that everything after the commands "borg-migrate source" and "borg-migrate target" are the your well-known borg elements found with "borg --help".
