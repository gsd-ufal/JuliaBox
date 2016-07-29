import os
import sh
import threading
import tarfile

from juliabox.jbox_util import ensure_delete, unique_sessname, make_sure_path_exists, JBoxCfg
from juliabox.vol import JBoxVol
from juliabox.interactive import SessContainer


class JBoxPolsarDiskVol(JBoxVol):
    provides = [JBoxVol.JBP_POLSAR]

    FS_LOC = None

    @staticmethod
    def configure():
        polsar_location = os.path.expanduser(JBoxCfg.get('polsar_location'))

        make_sure_path_exists(polsar_location)

        JBoxPolsarDiskVol.FS_LOC = polsar_location
        JBoxPolsarDiskVol.refresh_disk_use_status()

    @staticmethod
    def _get_disk_ids_used(cid):
        used = []
        props = JBoxPolsarDiskVol.dckr().inspect_container(cid)
        try:
            for _cpath, hpath in JBoxVol.extract_mounts(props):
                if hpath.startswith(JBoxPolsarDiskVol.FS_LOC):
                    used.append(hpath.split('/')[-1])
        except:
            JBoxPolsarDiskVol.log_error("error finding polsar disk ids used in " + cid)
            return []
        return used

    @staticmethod
    def refresh_disk_use_status(container_id_list=None):
        pass

    @staticmethod
    def get_disk_for_user(user_email):
        JBoxPolsarDiskVol.log_debug("Mounting polsar disk for %s", user_email)

        disk_id = unique_sessname(user_email)
        disk_path = JBoxPolsarDiskVol.FS_LOC
        if not os.path.exists(disk_path):
            os.mkdir(disk_path)

        polsarvol = JBoxPolsarDiskVol(disk_path, user_email=user_email)
        return polsarvol

    @staticmethod
    def is_mount_path(fs_path):
        return fs_path.startswith(JBoxPolsarDiskVol.FS_LOC)

    @staticmethod
    def get_disk_from_container(cid):
        mounts_used = JBoxPolsarDiskVol._get_disk_ids_used(cid)
        if len(mounts_used) == 0:
            return None

        mount_used = mounts_used[0]
        disk_path = os.path.join(JBoxPolsarDiskVol.FS_LOC, str(mount_used))
        container_name = JBoxVol.get_cname(cid)
        sessname = container_name[1:]
        return JBoxPolsarDiskVol(disk_path, sessname=sessname)

    @staticmethod
    def refresh_user_home_image():
        pass

    def release(self, backup=False):
        pass

    @staticmethod
    def disk_ids_used_pct():
        return 0
