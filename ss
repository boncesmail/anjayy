
<?php
session_start();

$pass = "asikinaja";
$root = realpath(__DIR__);

if (isset($_GET['out'])) {
    session_destroy();
    header("Location: ?");
    exit;
}

if (isset($_POST['p']) && hash_equals($pass, $_POST['p'])) {
    $_SESSION['ok'] = 1;
}

if (empty($_SESSION['ok'])) {
    echo '<form method="post">
    Password: <input type="password" name="p">
    <button type="submit">Login</button>
    </form>';
    exit;
}

function safePath($root, $input) {
    $path = realpath($input);
    if (!$path || ($path !== $root &&
        strpos($path, $root . DIRECTORY_SEPARATOR) !== 0)) {
        return false;
    }
    return $path;
}

$path = safePath($root, $_GET['d'] ?? $root);
if (!$path || !is_dir($path)) $path = $root;

$msg = "";
$editFile = null;
$content = "";

// Save file
if (isset($_POST['save'])) {
    $target = safePath($root, $_POST['file'] ?? '');
    if ($target && is_file($target) && is_writable($target)
        && isset($_POST['content'])) {
        if (file_put_contents($target, $_POST['content'], LOCK_EX) !== false) {
            $msg = "File berhasil disimpan!";
        } else {
            $msg = "Gagal menyimpan file.";
        }
    } else {
        $msg = "File tidak valid atau tidak dapat ditulis.";
    }
}

// Upload file
if (!empty($_FILES['f']['tmp_name'])) {
    $name = basename($_FILES['f']['name']);
    $destination = $path . DIRECTORY_SEPARATOR . $name;

    if (is_uploaded_file($_FILES['f']['tmp_name'])
        && !file_exists($destination)) {
        if (move_uploaded_file($_FILES['f']['tmp_name'], $destination)) {
            $msg = "Upload berhasil!";
        }
    } else {
        $msg = "Upload gagal atau nama file sudah digunakan.";
    }
}

// Delete file
if (isset($_GET['del'])) {
    $target = safePath($root, $path . DIRECTORY_SEPARATOR . basename($_GET['del']));
    if ($target && is_file($target) && is_writable($target)) {
        unlink($target);
        $msg = "File berhasil dihapus.";
    }
}

// Create new file
if (isset($_POST['create_file'])) {
    $name = basename(trim($_POST['new_file'] ?? ''));

    if ($name !== '' && $name !== '.' && $name !== '..'
        && preg_match('/^[a-zA-Z0-9._-]+$/', $name)) {

        $newPath = $path . DIRECTORY_SEPARATOR . $name;

        if (!file_exists($newPath)) {
            if (file_put_contents($newPath, '', LOCK_EX) !== false) {
                $msg = "File berhasil dibuat!";
            } else {
                $msg = "Gagal membuat file.";
            }
        } else {
            $msg = "Nama file sudah tersedia.";
        }
    } else {
        $msg = "Nama file tidak valid.";
    }
}

// Create new folder
if (isset($_POST['create_folder'])) {
    $name = basename(trim($_POST['new_folder'] ?? ''));

    if ($name !== '' && $name !== '.' && $name !== '..'
        && preg_match('/^[a-zA-Z0-9._-]+$/', $name)) {

        $newPath = $path . DIRECTORY_SEPARATOR . $name;

        if (!file_exists($newPath)) {
            if (mkdir($newPath, 0755)) {
                $msg = "Folder berhasil dibuat!";
            } else {
                $msg = "Gagal membuat folder.";
            }
        } else {
            $msg = "Nama folder sudah tersedia.";
        }
    } else {
        $msg = "Nama folder tidak valid.";
    }
}

// Open editor
if (isset($_GET['edit'])) {
    $target = safePath($root, $path . DIRECTORY_SEPARATOR . basename($_GET['edit']));
    if ($target && is_file($target) && is_readable($target)
        && filesize($target) <= 1048576) {
        $editFile = $target;
        $content = file_get_contents($target);
    }
}

$files = scandir($path);
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>PHP File Manager</title>
<style>
body {
    background:#000;color:#0f0;
    font-family:monospace;padding:15px;
}
a {color:cyan;text-decoration:none}
input,textarea,button {
    background:#111;color:#0f0;
    border:1px solid #444;padding:8px;
}
textarea {
    width:98%;height:450px;
    font-family:monospace;
}
li {padding:7px;border-bottom:1px solid #222}
button {cursor:pointer}
.msg {color:yellow}
</style>
</head>
<body>

<h2>PHP FILE MANAGER</h2>

<a href="?out=1" style="color:red">Logout</a>
<hr>

<b>Path:</b> <?=htmlspecialchars($path)?>

<?php if ($msg): ?>
<p class="msg"><?=htmlspecialchars($msg)?></p>
<?php endif; ?>

<?php if ($editFile): ?>

<h3>Edit File:
<?=htmlspecialchars(basename($editFile))?></h3>

<form method="post">
<input type="hidden" name="file"
value="<?=htmlspecialchars($editFile)?>">

<textarea name="content" spellcheck="false"><?=htmlspecialchars($content)?></textarea>
<br><br>
<button type="submit" name="save" value="1">SAVE FILE</button>
<a href="?d=<?=urlencode($path)?>">BACK</a>
</form>

<?php else: ?>

<h3>Upload File</h3>
<form method="post" enctype="multipart/form-data">
<input type="file" name="f" required>
<button type="submit">UPLOAD</button>
</form>

<hr>
<h3>Daftar File</h3>

<hr>

<h3>Create New File</h3>
<form method="post">
    <input type="text"
           name="new_file"
           placeholder="contoh: index.php"
           required>
    <button type="submit" name="create_file" value="1">
        CREATE FILE
    </button>
</form>

<h3>Create New Folder</h3>
<form method="post">
    <input type="text"
           name="new_folder"
           placeholder="Nama folder"
           required>
    <button type="submit" name="create_folder" value="1">
        CREATE FOLDER
    </button>
</form>

<hr>

<?php
$parent = dirname($path);
if ($path !== $root && safePath($root, $parent)) {
    echo '<p><a href="?d='.urlencode($parent).'">[.. Kembali]</a></p>';
}
?>

<ul>
<?php foreach ($files as $f):
    if ($f === '.') continue;

    $fp = $path . DIRECTORY_SEPARATOR . $f;
    $isDir = is_dir($fp);
?>
<li>
<?php if ($isDir): ?>
[DIR] <a href="?d=<?=urlencode($fp)?>">
<?=htmlspecialchars($f)?></a>
<?php else: ?>
[FILE] <?=htmlspecialchars($f)?>

<a href="?d=<?=urlencode($path)?>&edit=<?=urlencode($f)?>">
[EDIT / VIEW]</a>

<a href="?d=<?=urlencode($path)?>&del=<?=urlencode($f)?>"
onclick="return confirm('Hapus file ini?')"
style="color:red">[DELETE]</a>
<?php endif; ?>
</li>
<?php endforeach; ?>
</ul>

<?php endif; ?>

</body>
</html>
